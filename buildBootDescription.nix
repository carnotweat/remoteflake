# SPDX-License-Identifier: CC0-1.0

# Generate a total boot description by matching the binaries referred to by an init
# configuration with a list of input packages.

{ lib, runCommand, writeText, dhall-json, self, pkgs }:

{ name, initConfig, imageInputs, extraBinaries ? [ ], extraRoms ? { } }:

with builtins;
let
  extractDrv = lib.runDhallCommand "binaries.json" {
    nativeBuildInputs = [ dhall-json ];
  } ''
    dhall-to-json << TRUE_DEATH > $out
    let Genode = env:DHALL_GENODE
    let init = ${initConfig}
    in Genode.Init.Child.binaries (Genode.Init.toChild init Genode.Init.Attributes::{=})
    TRUE_DEATH
  '';
  binariesJSON = readFile (toString extractDrv);
  binaries = lib.unique (fromJSON binariesJSON ++ extraBinaries);

  matches = let
    f = binary: {
      name = binary;
      value = let maybeNull = map (drv: toPath "${drv}/${binary}") imageInputs;
      in filter pathExists maybeNull;
    };
  in map f binaries;

  binaryPaths = let
    f = { name, value }:
      let l = length value;
      in if l == 1 then {
        inherit name;
        value = elemAt value 0;
      } else if l == 0 then
        throw "${name} not found in imageInputs"
      else
        throw "${name} found in multiple imageInputs, ${toString value}";
  in map f matches;

  extraList =
    lib.mapAttrsToList (name: value: { inherit name value; }) extraRoms;

in writeText "${name}.boot.dhall" ''
  let Genode = env:DHALL_GENODE
  in  { config = ${initConfig}
      , rom = Genode.BootModules.toRomPaths ([
   ${
     toString (map ({ name, value }: ''
       , { mapKey = "${name}", mapValue = "${value}" }
     '') (binaryPaths ++ extraList))
   }
        ])
      }
''
