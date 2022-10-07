# Generate a total boot description by matching the binaries referred to by an init
# configuration with a list of input packages.

{ lib, writeText, dhall-json }:

{ initConfig, imageInputs, extraBinaries ? [ ], extraRoms ? { } }:

with builtins;
let
  extractDrv = lib.runDhallCommand "binaries.json" {
    nativeBuildInputs = [ dhall-json ];
  } ''
    dhall-to-json << EOF > $out
    let Sigil = env:DHALL_SIGIL
    let init = ${initConfig}
    in Sigil.Init.Child.binaries (Sigil.Init.toChild init Sigil.Init.Attributes::{=})
    EOF
  '';
  binariesJSON = readFile (toString extractDrv);
  binaries = lib.unique (fromJSON binariesJSON ++ extraBinaries);

  matches = let
    f = binary: {
      name = binary;
      value = let
        f = drv:
          if lib.hasPrefix "lib" binary && lib.hasSuffix ".so" binary
          && pathExists "${drv.lib or drv}/lib" then
            toPath "${drv.lib or drv}/lib/${binary}"
          else
            toPath (if pathExists "${drv}/bin" then
              "${drv}/bin/${binary}"
            else
              "${drv}/${binary}");
      in filter pathExists (map f imageInputs);
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

in writeText "boot.dhall" ''
  let Sigil = env:DHALL_SIGIL
  in  { config = ${initConfig}
      , rom = Sigil.BootModules.toRomPaths ([
   ${
     toString (map ({ name, value }: ''
       , { mapKey = "${name}", mapValue = "${value}" }
     '') (binaryPaths ++ extraList))
   }
        ])
      }
''
