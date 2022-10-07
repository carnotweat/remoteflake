{
  description = "Nix flavored Genode distribution";

  inputs.nixpkgs.url = "github:ehmry/nixpkgs/sigil-21";

  outputs = { self, nixpkgs, nimble }:
    let
      systems = {
        localSystem = [ "x86_64-linux" ]; # build platforms
        crossSystem = [ "aarch64-genode" "x86_64-genode" ]; # target platforms
      };

      systemSpace =
        # All combinations of build and target systems
        nixpkgs.lib.cartesianProductOfSets systems;

      forAllLocalSystems =
        # Apply a function over all self-hosting (Linux) systems.
        f:
        nixpkgs.lib.genAttrs systems.localSystem (system: f system);

      forAllCrossSystems =
        # Apply a function over all cross-compiled systems (Genode).
        f:
        with builtins;
        let
          f' = { localSystem, crossSystem }:
            let system = localSystem + "-" + crossSystem;
            in {
              name = system;
              value = f { inherit system localSystem crossSystem; };
            };
          list = map f' systemSpace;
          attrSet = listToAttrs list;
        in attrSet;

      forAllSystems =
        # Apply a function over all Linux and Genode systems.
        f:
        (forAllCrossSystems f) // (forAllLocalSystems (system:
          f {
            inherit system;
            localSystem = system;
            crossSystem = system;
          }));

    in rec {

      overlay =
        # Overlay of adjustments applied to Nixpkgs as well as
        # the "genodePackages" set which the "packages"
        # output of this flake is taken.
        import /etc/nixos/overlay { flake = self; };
      modules =
        import /etc/nixos/configuration.nix ;
        

      lib =
        # Local utilities merged with the Nixpkgs lib
        nixpkgs.lib.extend (final: prev: {
          inherit forAllSystems forAllLocalSystems forAllCrossSystems;

          getEris =
            # For a the name of a derivation output and a derivation,
            # generate a set of { cap, closure, and path } for a singular
            # file found within the subdirectory of the output with the
            # same name as that output. In the case that the derivation
            # does not have this named output, the subdirectory will be
            # taken from the default output. This subdirectory must
            # contain a single file, and the output must contain an
            # ERIS manifest file.
            output: pkg:
            with builtins;
            let
              pkg' = prev.getOutput output pkg;
              erisInfo = fromJSON (builtins.unsafeDiscardStringContext
                (readFile "${pkg'}/nix-support/eris-manifest.json"));
              caps = filter
                ({ path, ... }: prev.strings.hasPrefix "${pkg'}/${output}" path)
                (prev.attrsets.mapAttrsToList (path:
                  { cap, closure }: {
                    path = "${pkg'}${
                        substring (stringLength pkg') (stringLength path) path
                      }"; # hack to build a string with context
                    inherit cap closure;
                  }) erisInfo);
            in assert length caps == 1; head caps;

          getEris' = output: pkg: file:
            # A variant of the getEris function with file selection.
            with builtins;
            let
              pkg' = prev.getOutput output pkg;
              path' = "${pkg'}/${output}/${file}";
              erisInfo = fromJSON (builtins.unsafeDiscardStringContext
                (readFile "${pkg'}/nix-support/eris-manifest.json"));
              caps = filter ({ path, ... }: path == path')
                (prev.attrsets.mapAttrsToList (path:
                  { cap, closure }: {
                    path = "${pkg'}${
                        substring (stringLength pkg') (stringLength path) path
                      }"; # hack to build a string with context
                    inherit cap closure;
                  }) erisInfo);
            in assert length caps == 1; head caps;

          # uuidFrom = seed:
          #   let digest = builtins.hashString "sha256" seed;
          #   in (lib.lists.foldl ({ str, off }:
          #     n:
          #     let chunk = builtins.substring off n digest;
          #     in {
          #       str = if off == 0 then chunk else "${str}-${chunk}";
          #       off = off + n;
          #     }) {
          #       str = "";
          #       off = 0;
          #     } [ 8 4 4 4 12 ]).str;

          nixosSystem =
            # A derivative of the function for generating Linux NixOS systems.
            # This one is not so well tested…
            { modules, ... }@args:
            import "${nixpkgs}/nixos/lib/eval-config.nix" (args // {
              lib = final;

              baseModules =
                # TODO: do not blacklist modules for the Linux guests
                with builtins;
                let
                  isNotModule = suffix:
                    let x = "${nixpkgs}/nixos/modules/${suffix}";
                    in y: x != y;

                  filters = map isNotModule
                    (import ./nixos-modules/base-modules-blacklist.nix);

                  isCompatible = p:
                    let p' = toString p;
                    in all (f: f p') filters;

                in filter isCompatible
                (import "${nixpkgs}/nixos/modules/module-list.nix");

              modules = modules ++ [
                ({ config, lib, ... }: {
                  options = with lib; {

                    system.boot.loader.id = mkOption {
                      internal = true;
                      default = "";
                    };

                    system.boot.loader.kernelFile = mkOption {
                      internal = true;
                      default = pkgs.stdenv.hostPlatform.platform.kernelTarget;
                      type = types.str;
                    };

                    system.boot.loader.initrdFile = mkOption {
                      internal = true;
                      default = "initrd";
                      type = types.str;
                    };

                    systemd.defaultUnit = mkOption {
                      default = "multi-user.target";
                      type = types.str;
                    };

                  };
                  config = {

                    boot.loader.grub.enable = lib.mkDefault false;

                    fileSystems."/" = { };

                    networking.enableIPv6 = lib.mkForce false;
                    systemd.network.enable = lib.mkForce false;

                    system.nixos.versionSuffix = ".${
                        final.substring 0 8
                        (self.lastModifiedDate or self.lastModified or "19700101")
                      }.${self.shortRev or "dirty"}";

                    system.nixos.revision = final.mkIf (self ? rev) self.rev;

                    system.build.toplevel = config.system.build.initXml;

                  };

                })
              ];
            });

        });

      legacyPackages =
        # The nixpkgs.legacyPackages set after overlaying.
        let f = import nixpkgs;
        in forAllSystems ({ system, localSystem, crossSystem }:
          if localSystem == crossSystem then
            nixpkgs.legacyPackages.${system}.extend self.overlay
          else
            f {
              inherit localSystem;
              crossSystem = {
                system = crossSystem;
                useLLVM = true;
              };
              config.allowUnsupportedSystem = true;
              overlays = [ self.overlay ];
            });

      packages =
        # Genode native packages, not packages in the traditional
        # sense in that these cannot be installed within a profile.
        forAllCrossSystems ({ system, localSystem, crossSystem }:
          nixpkgs.lib.filterAttrs (_: v: v != null)
          self.legacyPackages.${system}.genodePackages);

      devShell =
        # Development shell for working with the
        # upstream Genode source repositories. Some
        # things are missing but everything referred
        # to by way of #!/usr/bin/ should be here.
        forAllLocalSystems (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            fhs = pkgs.buildFHSUserEnv {
              name = "genode-env";
              targetPkgs = pkgs:
                (with pkgs; [
                  binutils
                  bison
                  expect
                  flex
                  git
                  glibc.dev
                  gnumake
                  libxml2
                  qemu
                  rpcsvc-proto
                  subversion
                  tcl
                  wget
                  which
                  xorriso
                ]);
              runScript = "bash";
              extraBuildCommands = let
                toolchain = pkgs.fetchzip {
                  url =
                    "file://${packages.x86_64-linux-x86_64-genode.genodeSources.toolchain.src}";
                  hash = "sha256-26rPvLUPEJm40zLSqTquwuFTJ1idTB0T4VXgaHRN+4o=";
                };
              in "ln -s ${toolchain}/local usr/local";
            };
          in pkgs.stdenv.mkDerivation {
            name = "genode-fhs-shell";
            nativeBuildInputs = [ fhs ];
            shellHook = "exec genode-env";
          });

      nixosModules =
        # Modules for composing Genode and NixOS.
        import ./nixos-modules { flake = self; };
        #import /etc/nixos/configuration.nix { flake = self; };
      checks =
        # Checks for continous testing.
        let tests = import ./tests;
        in with (forAllCrossSystems ({ system, localSystem, crossSystem }:
          tests {
            flake = self;
            inherit system localSystem crossSystem;
            pkgs = self.legacyPackages.${system};
          } // {
            ports = self.legacyPackages.${localSystem}.symlinkJoin {
              name = "ports";
              paths = (builtins.attrValues
                self.packages.${system}.genodeSources.ports);
            };
          })); {
            x86_64-linux = x86_64-linux
              // x86_64-linux-x86_64-linux;
          };

      hydraJobs = self.checks;

    };
}
