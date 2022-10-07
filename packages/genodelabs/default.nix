{ final, prev }:

let
  inherit (final) lib;
  inherit (prev.buildPackages) buildPackages;

  platform = final.targetPlatform;

  arch = with platform;
    if isx86_64 then
      "x86_64"
    else if isAarch64 then
      "arm_v8a"
    else
      throw "unknown Genode arch for platform ${platform.system}";

  upstreamSources =
    # This is where the Genode source tree is defined.
    # Must be updated with ./patches/sources.patch.
    buildPackages.fetchFromGitHub {
      owner = "genodelabs";
      repo = "genode";
      rev = "sculpt-21.03";
      hash = "sha256-rbrzhSUXRaL1RhQ2GDBrRTIOt6o0TYhi5GOXjKa71Nc=";
    };

  genodeSources =
    # The Genode source repository after patching.
    let
      toolPrefix = if platform.isx86 then
        "genode-x86-"
      else if platform.isAarch64 then
        "genode-aarch64-"
      else
        throw "unknown tool prefix for Genode arch ${arch}";
    in with buildPackages;
    stdenvNoCC.mkDerivation {
      pname = "genode-sources";
      version = builtins.substring 0 7 upstreamSources.rev;
      src = upstreamSources;
      nativeBuildInputs = [ expect gnumake tcl ];
      patches = [ ./patches/sources.patch ];
      configurePhase = ''
        patchShebangs ./tool
        substituteInPlace repos/base/etc/tools.conf \
          --replace "/usr/local/genode/tool/19.05/bin/" ""
        substituteInPlace tool/check_abi \
          --replace "exec nm" "exec ${toolPrefix}nm"
      '';

      buildPhase = ''
        echo { >> ports.nix
        find repos/*/ports -name '*.hash' | while read hashFile
        do
          echo "  $(basename --suffix=.hash $hashFile) = \"$(cut -c -6 $hashFile)\";" >> ports.nix
        done
        echo } >> ports.nix
      '';

      installPhase = "cp -a . $out";
    };

  portVersions =
    # Port versions are taken from the sources to force
    # updates of the port fixed-output derivations.
    import "${genodeSources}/ports.nix";

  preparePort =
    # Prepare a "port" of source code declared in the Genode sources.
    # This is fragile because breakage can appear when the packages
    # used in preparation are updated, but previously successful
    # builds will cache.
    name:
    { hash ? "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    , patches ? [ ], extraRepos ? [ ], ... }@args:
    let
      dontUnpack = patches == [ ] && extraRepos == [ ];
      version = portVersions.${name} or args.version;
    in with buildPackages.buildPackages;
    stdenvNoCC.mkDerivation (args // {
      name = name + "-port-" + version;
      inherit version patches dontUnpack extraRepos;
      preferLocalBuild = true;
      outputHashMode = "recursive";
      outputHash = hash;

      GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";
      VERBOSE = "";
      # need to build in verbose mode because errors are hidden

      impureEnvVars = lib.fetchers.proxyImpureEnvVars
        ++ [ "GIT_PROXY_COMMAND" "SOCKS_SERVER" ];

      src = if dontUnpack then null else genodeSources;

      dontConfigure = true;

      nativeBuildInputs =
        [ bison flex gitMinimal glibc glibcLocales wget which ]
        ++ (args.nativeBuildInputs or [ ]);

      buildPhase =
        # ignore the port hash, its only for the inputs
        ''
          runHook preBuild
          export CONTRIB_DIR=$NIX_BUILD_TOP/contrib
          export GENODE_CONTRIB_CACHE=$NIX_BUILD_TOP/contrib/cache
          export GENODE_DIR=${if dontUnpack then genodeSources else "$(pwd)"}
          for repo in $extraRepos; do
            ln -s $repo $GENODE_DIR/repos/
          done
          mkdir $CONTRIB_DIR
          $GENODE_DIR/tool/ports/prepare_port ${name} CHECK_HASH=no
          runHook postBuild
        '';

      installPhase =
        # strip non-deterministic and extra artifacts
        ''
          runHook preInstall
          chmod -R +w $CONTRIB_DIR/*
          find $CONTRIB_DIR/* -name cache -exec rm -rf {} \; || true
          find $CONTRIB_DIR/* -name .git -exec rm -rf {} \; || true
          find $CONTRIB_DIR/* -name .svn -exec rm -rf {} \; || true
          find $CONTRIB_DIR/* -name '*.t?z' -exec rm -rf {} \; || true
          find $CONTRIB_DIR/* -name '*.tar.*' -exec rm -rf {} \; || true
          find $CONTRIB_DIR/* -name '*.zip' -exec rm -rf {} \; || true

          mkdir $out
          cp -av $CONTRIB_DIR/* $out/
          runHook postInstall
        '';

      dontFixup = true;
    });

  ports =
    # The "ports" mechanism is hardly deterministic, so prepare with
    # a pinned nixpkgs revision for a pinned platform for consistency.
    lib.mapAttrs preparePort (import ./ports.nix {
      pkgs = buildPackages;
      inherit (final.genodePackages) worldSources;
    });

  toolchain =
    # Patched GCC build from upstream.
    buildPackages.buildPackages.callPackage ./toolchain.nix { };

  stdenv' =
    # Special stdenv for use within the upstream sources.
    # TODO: build with Clang.
    final.stdenvAdapters.overrideCC final.stdenv toolchain;

  buildUpstream =
    # Build from the Genode sources using the least recursive make.
    { name, targets, portInputs ? [ ], nativeBuildInputs ? [ ], patches ? [ ]
    , enableParallelBuilding ? true, meta ? { }, ... }@extraAttrs:
    let havePatches = patches != [ ];

    in stdenv'.mkDerivation (extraAttrs // {
      pname = name;
      inherit (genodeSources) version;
      inherit targets patches enableParallelBuilding;

      src = if havePatches then genodeSources else null;
      dontUnpack = !havePatches;

      nativeBuildInputs = with buildPackages;
        [ binutils bison flex stdenv.cc tcl which ] ++ nativeBuildInputs;

      configurePhase = let
        linkPorts = toString
          (builtins.map (drv: " ln -sv ${drv}/* $CONTRIB_DIR/;") portInputs);
      in ''
        runHook preConfigure
        export CONTRIB_DIR=$NIX_BUILD_TOP/contrib
        export BUILD_DIR=$(pwd)/build
        export GENODE_DIR=${if havePatches then "$(pwd)" else genodeSources}

        $GENODE_DIR/tool/create_builddir ${arch}
        substituteInPlace $BUILD_DIR/etc/build.conf \
          --replace "#REPOSITORIES" "REPOSITORIES"
        mkdir $CONTRIB_DIR; ${linkPorts}
        runHook postConfigure
      '';

      STRIP_TARGET_CMD = "cp $< $@";

      makeFlags = [ "-C build" "VERBOSE=" ] ++ targets;

      installPhase = ''
        runHook preInstall
        find build/bin -name '*.xsd' -delete
        find build/bin -follow -type f -name '*.lib.so' \
          -exec install -Dt "''${!outputLib}/lib" {} \; -delete
        find build/bin -follow -type f -executable \
          -exec install -Dt "''${!outputBin}/bin" {} \;
        runHook postInstall
      '';

      meta = { platforms = lib.platforms.genode; } // meta;
    });

  buildDepot =
    # Build from the Genode sources using the depot build system.
    # WARNING: buildDepot can produce artifacts with broken linkage
    # to their inputs. The Genode depot mechanism links programs and
    # libraries to facsimilie stub libraries which are not guaranteed
    # to have the same ABI as the current version as the real library.
    { name, portInputs ? [ ], depotInputs ? [ ], nativeBuildInputs ? [ ]
    , buildInputs ? [ ], meta ? { }, ... }@extraAttrs:

    let
      getDepotInputs = lib.concatMap (x:
        [ x ] ++ x.passthru.depotInputs
        ++ (getDepotInputs x.passthru.depotInputs));

      depotInputs' = lib.lists.unique (getDepotInputs depotInputs);

      portInputs' = portInputs
        ++ lib.concatMap (builtins.getAttr "portInputs") depotInputs';

      self = stdenv'.mkDerivation (extraAttrs // {
        pname = name;
        inherit (genodeSources) version;
        enableParallelBuilding = true;

        nativeBuildInputs = with buildPackages.buildPackages;
          [ binutils bison flex stdenv.cc tcl which ] ++ nativeBuildInputs
          ++ lib.optional (!stdenv.hostPlatform.isGenode) erisPatchHook;

        buildInputs = buildInputs ++ depotInputs';

        src = genodeSources;
        # The genode source tree must be copied to the build directory
        # because the depot tool must modify the source tree as it runs.

        configurePhase = let
          copyPorts = # wasteful copy
            toString
            (builtins.map (drv: " cp -r ${drv}/* $CONTRIB_DIR/;") portInputs');
        in ''
          runHook preConfigure
          export GENODE_DIR=$(pwd)
          export CONTRIB_DIR=$GENODE_DIR/contrib
          export DEPOT_DIR=$GENODE_DIR/depot
          mkdir -p $CONTRIB_DIR; ${copyPorts}
          chmod +rwX -R .
          runHook postConfigure
        '';

        STRIP_TARGET_CMD = "cp $< $@";
        # defer strip until fixup phase

        makefile = "tool/depot/create";
        makeFlags = [
          "genodelabs/bin/${arch}/${name}"

          # by default the build system will refuse to be useful
          "FORCE=1"
          "KEEP_BUILD_DIR=1"
          "UPDATE_VERSIONS=1"
          "VERBOSE="
        ];

        installPhase = ''
          runHook preInstall
          rm -r depot/genodelabs/bin/${arch}/${name}/*\.build

          local outputBinDir="''${!outputBin}/bin"
          local outputLibDir="''${!outputLib}/lib"
          find depot/genodelabs/bin/${arch}/${name} -name '*.lib.so' \
            -exec install -Dt "$outputLibDir" {} \; -delete
          if [ -d "$outputLibDir" ]; then
            pushd "$outputLibDir"
            for src in *.lib.so; do
              dst=$src
              dst="''${dst#lib}"
              dst="''${dst%.lib.so}"
              ln -s "$src" lib"$dst".so
            done
            popd
          fi

          find depot/genodelabs/bin/${arch}/${name} -executable \
            -exec install -Dt "$outputBinDir" {} \;

          runHook postInstall
        '';

        passthru = { inherit portInputs depotInputs; };
        meta = { platforms = lib.platforms.genode; } // meta;
      });
    in self;

  makePackages =
    # Build everything in ./make-targets.nix.
    let
      overrides = import ./make-targets.nix {
        inherit (final) genodePackages;
        inherit buildPackages ports;
      };
    in lib.attrsets.mapAttrs
    (name: value: (buildUpstream ({ inherit name; } // value))) overrides;

  depotPackages = lib.attrsets.mapAttrs
    # Build everything in ./depot-targets.nix.
    (name: value: (buildDepot ({ inherit name; } // value)))
    (import ./depot-targets.nix {
      inherit (final) genodePackages;
      inherit buildPackages ports;
    });

  specs = with platform;
    [ ]

    ++ lib.optional is32bit "32bit"

    ++ lib.optional is64bit "64bit"

    ++ lib.optional isAarch32 "arm"

    ++ lib.optional isAarch64 "arm_64"

    ++ lib.optional isRiscV "riscv"

    ++ lib.optional isx86 "x86"

    ++ lib.optional isx86_32 "x86_32"

    ++ lib.optional isx86_64 "x86_64";

  genodeBase =
    # A package containing the Genode C++ headers
    # and a stub ld.lib.so and vfs.lib.so.
    buildUpstream {
      name = "base";
      targets = [ "LIB=vfs" ];
      postInstall =
        # The actual ld.lib.so is kernel specific
        # so ship the stubbed library for linking
        ''
          cp $BUILD_DIR/var/libcache/ld/ld.abi.so $out/ld.lib.so
          mkdir -p $out/include
          cp -r --no-preserve=mode \
            $GENODE_DIR/repos/base/include/* \
            $GENODE_DIR/repos/os/include/* \
            $GENODE_DIR/repos/demo/include/* \
            $GENODE_DIR/repos/gems/include/* \
            $out/include/
          for spec in ${toString specs}; do
            dir=$out/include/spec/$spec
            if [ -d $dir ]; then
              cp -r $dir/* $out/include/
            fi
          done
          rm -rf $out/include/spec
          cp -r $GENODE_DIR/repos/base/src/ld $out/ld
        '';
    };

in makePackages // depotPackages // {

  genodeSources =
    # Expose genodeSources and tuck some extras in with it.
    genodeSources // {
      inherit arch buildUpstream buildDepot genodeBase ports specs toolchain;
    };

  # Builds of the Genode base-systems follow.
  # These contain the hardware and kernel specific core program,
  # the loader and base-library, and a timer driver.

  base-hw-pc = buildUpstream {
    name = "base-hw-pc";
    outputs = [ "out" "coreObj" "bootstrapObj" ];
    KERNEL = "hw";
    BOARD = "pc";
    targets = [ "bootstrap" "core" "timer" "lib/ld" ];
    postInstall = ''
      mv $out/lib/ld-hw.lib.so $out/lib/ld.lib.so
      mv $out/bin/hw_timer_drv $out/bin/timer_drv
      install build/bin/core-hw-pc.o $coreObj
      install build/bin/bootstrap-hw-pc.o $bootstrapObj
    '';
    dontErisPatch = true;
    meta.platforms = [ "x86_64-genode" ];
  };

  base-hw-virt_qemu = buildUpstream {
    name = "base-hw-virt_qemu";
    outputs = [ "out" "coreObj" "bootstrapObj" ];
    KERNEL = "hw";
    BOARD = "virt_qemu";
    targets = [ "bootstrap" "core" "timer" "lib/ld" ];
    postInstall = ''
      mv $out/lib/ld-hw.lib.so $out/lib/ld.lib.so
      mv $out/bin/hw_timer_drv $out/bin/timer_drv
      install build/bin/core-hw-virt_qemu.o $coreObj
      install build/bin/bootstrap-hw-virt_qemu.o $bootstrapObj
    '';
    dontErisPatch = true;
    meta.platforms = [ "aarch64-genode" ];
  };

  base-linux = buildUpstream {
    name = "base-linux";
    KERNEL = "linux";
    BOARD = "linux";
    targets = [ "core" "timer" "lib/ld" ];
    postInstall = ''
      mv $out/lib/ld-linux.lib.so $out/lib/ld.lib.so
      mv $out/bin/linux_timer_drv $out/bin/timer_drv
    '';
    HOST_INC_DIR = buildPackages.glibc.dev + "/include";
    dontErisPatch = true;
  };

  base-nova = buildUpstream {
    name = "base-nova";
    outputs = [ "out" "coreObj" ];
    KERNEL = "nova";
    targets = [ "core" "timer" "lib/ld" ];
    postInstall = ''
      mv $out/lib/ld-nova.lib.so $out/lib/ld.lib.so
      mv $out/bin/nova_timer_drv $out/bin/timer_drv
      install $BUILD_DIR/bin/core-nova.a $coreObj
    '';
    dontErisPatch = true;
  };
}
