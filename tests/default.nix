{ flake, system, localSystem, crossSystem, pkgs }:

let
  lib = flake.lib;

  testingPython =
    # Mostly lifted from Nixpkgs.
    import ./lib/testing-python.nix;

  testSpace =
    # Run all tests on all defined Genode platforms
    lib.cartesianProductOfSets {

      test = map (p: import p) [
        ./ahci.nix
        ./bash.nix
        ./graphics.nix
        ./hello.nix
        ./log.nix
        ./nim.nix
        ./tor.nix
        ./usb.nix
        ./vmm_x86.nix
      ];

      core = builtins.filter (core:
        builtins.any (x: x == pkgs.stdenv.hostPlatform.system) core.platforms) [
          /* # Need to fix the QEMU boot parameters?
             {
               prefix = "hw-pc-";
               testingPython = testingPython {
                 inherit flake system localSystem crossSystem pkgs;
                 extraConfigurations = [ ../nixos-modules/base-hw-pc.nix ];
               };
               specs = [ "x86" "hw" ];
               platforms = [ "x86_64-genode" ];
             }
          */
          /* # Need to fix the QEMU boot parameters?
             {
               prefix = "hw-virt_qemu-";
               testingPython = testingPython {
                 inherit flake system localSystem crossSystem pkgs;
                 extraConfigurations = [ ../nixos-modules/base-hw-virt_qemu.nix ];
               };
               specs = [ "aarch64" "hw" ];
               platforms = [ "aarch64-genode" ];
             }
          */
          {
            prefix = "nova-";
            testingPython = testingPython {
              inherit flake system localSystem crossSystem pkgs;
              extraConfigurations = [ ../nixos-modules/nova.nix ];
            };
            specs = [ "x86" "nova" ];
            platforms = [ "x86_64-genode" ];
          }
        ];

    };

  testList = let
    f = { core, test }:
      if (test.constraints or (_: true)) core.specs then {
        name = core.prefix + test.name;
        value = core.testingPython.makeTest test;
      } else
        null;
  in map f testSpace;

in builtins.listToAttrs (builtins.filter (_: _ != null) testList)
