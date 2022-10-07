{ pkgs, legacyPackages, ... }:
with pkgs;

let
  inherit (legacyPackages) bash coreutils;
  script = with legacyPackages;
    writeTextFile {
      name = "posix.sh";
      text = ''
        export PATH=${
          lib.makeSearchPathOutput "bin" "bin"
          (with legacyPackages; [ bash hello coreutils ])
        }
        set -v
        time ls -lR /nix
        sleep 1
        hello -v
        sleep 1
        uname -a
      '';
    };
in rec {
  name = "posix";
  machine = {
    config = ''
      ${
        ./posix.dhall
      } { bash = \"${bash}\", coreutils = \"${coreutils}\", script = \"${script}\" }'';
    extraInputs =
      map pkgs.genodeSources.depot [ "libc" "posix" "vfs_pipe" "vfs" ]
      ++ [ bash ];
    extraPaths = [ script ] ++ (with legacyPackages; [ coreutils hello ]);
  };
}
