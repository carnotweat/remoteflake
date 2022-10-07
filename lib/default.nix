{ system, localSystem, crossSystem, pkgs }:

let
  inherit (pkgs) buildPackages;
  localPackages = pkgs.buildPackages.buildPackages;
  inherit (pkgs.genodePackages) dhallSigil genodeSources;

  dhallCachePrelude = ''
    export XDG_CACHE_HOME=$NIX_BUILD_TOP
    export DHALL_SIGIL="${dhallSigil}/binary.dhall";
    ${buildPackages.xorg.lndir}/bin/lndir -silent \
      ${dhallSigil}/.cache \
      $XDG_CACHE_HOME
  '';

in rec {

  runDhallCommand = name: env: script:
    pkgs.runCommand name (env // {
      nativeBuildInputs = [ localPackages.dhall ]
        ++ env.nativeBuildInputs or [ ];
    }) ''
      ${dhallCachePrelude}
      ${script}
    '';

  linuxScript = name: env: bootDhall:
    runDhallCommand name env ''
      dhall to-directory-tree --output $out \
        <<< "${./linux-script.dhall} (${bootDhall}) \"$out\""
    '';

  compileBoot = name: env: bootDhall:
    runDhallCommand "${name}-boot" env ''
      dhall to-directory-tree --output $out \
        <<< "${./compile-boot.dhall} (${bootDhall}) \"$out\""
      dhall <<< "(${bootDhall}).config" \
        | dhall encode \
        > $out/config.dhall.bin
    '';

  hwImage = coreLinkAddr: bootstrapLinkAddr: basePkg: name:
    { gzip ? false, ... }@env:
    boot:
    pkgs.stdenv.mkDerivation {
      name = name + "-hw-image";
      build = compileBoot name env boot;
      nativeBuildInputs = [ localPackages.dhall ];
      buildCommand = let
        bootstrapDhall =
          # snippet used to nest core.elf into image.elf
          builtins.toFile "boostrap.dall" ''
            let Sigil = env:DHALL_SIGIL

            in  { config = Sigil.Init.default
                , rom =
                    Sigil.BootModules.toRomPaths
                      [ { mapKey = "core.elf", mapValue = "./core.elf" } ]
                }
          '';
      in ''
        ${dhallCachePrelude}

        build_core() {
          local lib="$1"
          local modules="$2"
          local link_address="$3"
          local out="$4"

          # compile the boot modules into one object file
          $CC -c -x assembler -o "boot_modules.o" "$modules"

          # link final image
        LD="${buildPackages.binutils}/bin/${buildPackages.binutils.targetPrefix}ld"
          $LD \
            --strip-all \
            -T${genodeSources}/repos/base/src/ld/genode.ld \
            -z max-page-size=0x1000 \
            -Ttext=$link_address -gc-sections \
            "$lib" "boot_modules.o" \
            -o $out
        }

        build_core \
          "${basePkg.coreObj}" \
          "$build/modules_asm" \
          ${coreLinkAddr} \
          core.elf

        dhall to-directory-tree --output bootstrap \
          <<< "${./compile-boot.dhall} ${bootstrapDhall} \"bootstrap\""

        mkdir -p $out
        build_core \
          "${basePkg.bootstrapObj}" \
          bootstrap/modules_asm \
          ${bootstrapLinkAddr} \
          $out/image.elf
      '' + pkgs.lib.optionalString gzip "gzip $out/image.elf";
    };

  novaImage = name:
    { gzip ? false, ... }@env:
    boot:
    pkgs.buildPackages.stdenv.mkDerivation {
      name = name + "-nova-image";
      build = compileBoot name env boot;

      buildCommand = ''
        mkdir -p $out

        # compile the boot modules into one object file
        $CC -c -x assembler -o "boot_modules.o" "$build/modules_asm"

        # link final image
        LD="${buildPackages.binutils}/bin/${buildPackages.binutils.targetPrefix}ld"
        $LD --strip-all -nostdlib \
        	-T${genodeSources}/repos/base/src/ld/genode.ld \
        	-T${genodeSources}/repos/base-nova/src/core/core-bss.ld \
        	-z max-page-size=0x1000 \
        	-Ttext=0x100000 -gc-sections \
        	"${pkgs.genodePackages.base-nova.coreObj}" boot_modules.o \
        	-o $out/image.elf
      '' + pkgs.lib.optionalString gzip "gzip $out/image.elf";
    };

  mergeManifests = inputs:
    pkgs.writeTextFile {
      name = "manifest.dhall";
      text = with builtins;
        let
          f = head: input:
            if hasAttr "manifest" input then
              ''
                ${head}, { mapKey = "${
                  pkgs.lib.getName input
                }", mapValue = ${input.manifest} }''
            else
              abort "${input.pname} does not have a manifest";
        in (foldl' f "[" inputs) + "]";
    };

}
