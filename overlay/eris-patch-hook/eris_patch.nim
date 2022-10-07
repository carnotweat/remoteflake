import eris

import std/asyncdispatch, std/deques, std/json, std/os, std/osproc, std/streams,
    std/strutils, std/tables

if getEnv("dontErisPatch") != "": quit 0

let
  patchelf = getEnv("ERIS_PATCHELF", "patchelf")
  nixStore = getEnv("NIX_STORE", "/nix/store")
  manifestSubPath = "nix-support" / "eris-manifest.json"

const erisBlockSize = 32 shl 10
  # fix the block size for now

proc isElf(path: string): bool =
  var magic: array[4, char]
  let file = open(path)
  discard readChars(file, magic, 0, 4)
  close(file)
  magic == [0x7f.char, 'E', 'L', 'F']

type PendingFile = ref object
  outputRoot, filePath: string
  replacements: Table[string, string]

var
  outputManifests = initTable[string, JsonNode]()
  pendingFiles = initDeque[PendingFile]()
  failed = false
for outputName in getEnv("outputs").splitWhitespace:
  let outputRoot = getEnv(outputName)
  if fileExists(outputRoot / manifestSubPath):
    echo "Not running ERIS patch hook again"
    quit 0
  outputManifests[outputRoot] = newJObject()

let buildInputs = getEnv("buildInputs").splitWhitespace

proc resolveNeed(rpath: seq[string]; need: string): string =
  if need.isAbsolute:
    return need
  for libdir in rpath:
    let absNeed = libdir / need
    if fileExists(absNeed):
      return absNeed
  for outputRoot in outputManifests.keys:
    for relPath in [need, "lib" / need]:
      let absNeed = outputRoot / relPath
      if fileExists(absNeed):
        return absNeed
  for buildInput in buildInputs:
    for relPath in [need, "lib" / need]:
      let absNeed = buildInput / relPath
      if fileExists(absNeed):
        return absNeed

proc resolveFile(outputRoot, filePath: string): PendingFile =
  result = PendingFile(
      outputRoot: outputRoot,
      filePath: filePath,
      replacements: initTable[string, string](8))
  let needs = splitWhitespace(execProcess(
      patchelf, args = ["--print-needed", filePath], options = {poUsePath}))
  let rpath = splitWhitespace(execProcess(
      patchelf, args = ["--print-rpath", filePath], options = {poUsePath}))
  for need in needs:
    if need == "ld.lib.so" or need.startsWith("urn:"): continue
    result.replacements[need] = resolveNeed(rpath, need)

var capCache = initTable[string, Cap]()

proc fileUrn(filePath: string; blockSize: Natural): string =
  ## Determine the ERIS URN for ``filePath``.
  var cap: Cap
  if capCache.hasKey(filePath):
    cap = capCache[filePath]
  else:
    try:
      let str = newFileStream(filePath)
      doAssert(not str.isNil) # yes, that happens
      cap = waitFor encode(newDiscardStore(), blockSize, str)
      capCache["filePath"] = cap
      close(str)
    except:
      stderr.writeLine("failed to read \"", filePath, "\"")
      quit 1
  $cap # & "#" & encodeUrl(extractFilename(filePath), usePlus = false)

var closureCache = initTable[string, TableRef[string, string]]()

proc fileClosure(filePath: string): TableRef[string, string] =
  ## Recusively find the dependency closure of  ``filePath``.
  let filePath = expandFilename filePath
  if closureCache.hasKey(filePath):
    result = closureCache[filePath]
  else:
    result = newTable[string, string]()
    var storePath = filePath
    for p in parentDirs(filePath):
      # find the top directory of the ``filePath`` derivation
      if p == nixStore: break
      storePath = p
    if storePath.startsWith nixStore:
      # read the closure manifest of the dependency
      let manifestPath = storePath / manifestSubPath
      if fileExists(manifestPath):
        let
          manifest = parseFile(manifestPath)
          entry = manifest[filePath]
        for path, cap in entry["closure"].pairs:
          result[path] = cap.getStr
          let otherClosure = fileClosure(path)
          for otherPath, otherCap in otherClosure.pairs:
            # merge the closure of the dependency
            result[otherPath] = otherCap
    closureCache[filePath] = result

for outputRoot in outputManifests.keys:
  let manifestPath = outputRoot / manifestSubPath
  if fileExists manifestPath: continue
  for filePath in walkDirRec(outputRoot, relative = false):
    # Populate the queue of files to patch
    if filePath.isElf:
      pendingFiles.addLast(resolveFile(outputRoot, filePath))

var
  prevLen = pendingFiles.len
  prevPrevLen = prevLen.succ
    # used to detect reference cycles
while pendingFiles.len != 0:
  block selfReferenceCheck:
    # process the files that have been collected
    # taking care not to take a the URN of an
    # unprocessed file
    let
      pendingFile = pendingFiles.popFirst()
      filePath = pendingFile.filePath
    for need, replacementPath in pendingFile.replacements.pairs:
      # search for self-references
      if replacementPath == "":
        echo need, " not found for ", filePath
        failed = true
        continue
      for outputRoot in outputManifests.keys:
        if replacementPath.startsWith(outputRoot):
          for other in pendingFiles.items:
            echo "compare for self-reference:"
            echo '\t', replacementPath
            echo '\t', other.filePath
            if replacementPath == other.filePath:
              echo "defering patch of ", filePath, " with reference to ", other.filePath
              pendingFiles.addLast(pendingFile)
              break selfReferenceCheck
    var
      closure = newJObject()
      replaceCmd = patchelf & " --set-rpath '' " & filePath
    for need, replacementPath in pendingFile.replacements.pairs:
      if replacementPath == "": continue
      let urn = fileUrn(replacementPath, erisBlockSize)
      echo "replace reference to ", need, " with ", urn
      replaceCmd.add(" --replace-needed $# $#" % [need, urn])
      closure[replacementPath] = %urn
      for path, urn in fileClosure(replacementPath).pairs:
        closure[path] = %urn
    if pendingFile.replacements.len != 0:
      replaceCmd.add(" 2>&1")
      let (msg, exitCode) = execCmdEx(replaceCmd, options = {poUsePath})
      if exitCode != 0:
        echo "Patchelf failed"
        echo replaceCmd
        echo msg
        quit exitCode
    outputManifests[pendingFile.outputRoot][filePath] = %* {
      "cap": fileUrn(filePath, erisBlockSize),
      "closure": closure,
    }
  if pendingFiles.len == prevPrevLen:
    failed = true
    echo "reference cycle detected in the following:"
    for remain in pendingFiles.items:
      echo '\t', " ", remain.filePath
    break
  prevPrevLen = prevLen
  prevLen = pendingFiles.len

if failed:
  quit -1

for outputRoot, manifest in outputManifests:
  createDir(outputRoot / "nix-support")
  writeFile(outputRoot / manifestSubPath, $manifest)
