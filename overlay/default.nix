{ flake }:
final: prev:
with prev;

let
  # Helper functions to override package dependent
  # on whether the host or target system is Genode.

  overrideHost = attrs: drv:
    if hostPlatform.isGenode then drv.override attrs else drv;

  overrideAttrsHost = f: drv:
    if hostPlatform.isGenode then drv.overrideAttrs f else drv;

  overrideAttrsTarget = f: drv:
    if targetPlatform.isGenode then drv.overrideAttrs f else drv;

  addPatches' = patches: attrs: { patches = attrs.patches or [ ] ++ patches; };

  addPatchesHost = ps: overrideAttrsHost (addPatches' ps);

  addPatchesTarget = ps: overrideAttrsTarget (addPatches' ps);

  autoreconfHost =
    overrideAttrsHost (_: { nativeBuildInputs = [ final.autoreconfHook ]; });

  nullPkgs =
    # Nullify these packages to find problems early.
    if hostPlatform.isGenode then
      builtins.listToAttrs (map (name: {
        inherit name;
        value = final.hello;
      }) [ "iproute2" "strace" ])
    else
      { };

in nullPkgs // {

  bash = overrideAttrsTarget (attrs: {
    configureFlags = attrs.configureFlags
      ++ [ "--without-bash-malloc" ]; # no sbrk please
    postPatch = "sed '/check_dev_tty/d' shell.c";
  }) prev.bash;

  binutils-unwrapped = overrideAttrsTarget (attrs: {
    patches = attrs.patches ++ [
      ./binutils/support-genode.patch
      # Upstreamed, remove at next release.
    ];
    nativeBuildInputs = attrs.nativeBuildInputs
      ++ [ final.updateAutotoolsGnuConfigScriptsHook ];
  }) prev.binutils-unwrapped;

  cmake =
    # TODO: upstream
    overrideAttrsTarget (attrs: {
      postInstall = with stdenv; ''
        local MODULE="$out/share/cmake-${
          lib.versions.majorMinor attrs.version
        }/Modules/Platform/Genode.cmake"
        if [ -e "$MODULE" ]; then
            echo "Upstream provides $MODULE!"
            exit 1
        fi
        cp ${./cmake/Genode.cmake} $MODULE
      '';
    }) prev.cmake;

  coreutils = overrideHost {
    gmp = null;
    libiconv = null;
  } (overrideAttrsHost (_: {
    configureFlags = [
      "--disable-acl"
      "--disable-largefile"
      "--disable-xattr"
      "--disable-libcap"
      "--disable-nls"
    ];
    LDFLAGS = [ "-Wl,--no-as-needed" ];
    # keep libposix NEEDED
  }) prev.coreutils);

  erisPatchHook = final.callPackage ./eris-patch-hook {
    patchelf = prev.patchelf.overrideAttrs (attrs: {
      patches = attrs.patched or [ ] ++ [
        ./patchelf/dynstr.patch
        ./patchelf/shiftFile.patch
        ./patchelf/disable-assert.patch
      ];
    });
  };

  gdb = addPatchesTarget [
    ./gdb/genode.patch
    # Upstreamed, remove at next release.
  ] prev.gdb;

  genodeLibcCross = callPackage ./libc { };

  genodePackages =
    # The Genode-only packages.
    import ../packages { inherit final prev; };

  grub2 =
    # No need for a Genode build of GRUB.
    if stdenv.targetPlatform.isGenode then
      prev.buildPackages.grub2
    else
      prev.grub2;

  libcCrossChooser = name:
    if stdenv.targetPlatform.isGenode then
      targetPackages.genodeLibcCross
    else
      prev.libcCrossChooser name;

  libsodium = overrideAttrsHost (attrs: {
    patches = (attrs.patches or [ ]) ++ [
      ./libsodium/genode.patch
      # https://github.com/jedisct1/libsodium/pull/1006
    ];
  }) prev.libsodium;

  libkrb5 =
    # Do not want.
    autoreconfHost prev.libkrb5;

  libtool =
    # Autotools related nonesense. Better to compile
    # everything static than to deal with this one.
    overrideAttrsTarget (attrs: {
      nativeBuildInputs = with final;
        attrs.nativeBuildInputs ++ [ autoconf automake115x ];
      patches = ./libtool/genode.patch;
    }) prev.libtool;

  libtoxcore = overrideHost {
    libopus = null;
    libvpx = null;
  } prev.libtoxcore;

  linuxPackages =
    # Dummy package.
    if hostPlatform.isGenode then {
      extend = _: final.linuxPackages;
      features = { };
      kernel = {
        version = "999";
        config = {
          isEnabled = _: false;
          isYes = _: false;
        };
      };
    } else
      prev.linuxPackages;

  llvmPackages = if targetPlatform.isGenode then
    final.llvmPackages_11
  else
    prev.llvmPackages;

  llvmPackages_11 = if targetPlatform.isGenode then
    (import ./llvm-11/override.nix { inherit final prev; })
  else
    prev.llvmPackages_11;

  ncurses =
    # https://invisible-island.net/autoconf/
    # Stay clear of upstream on this one.
    addPatchesHost [ ./ncurses/genode.patch ] prev.ncurses;

  nim-unwrapped =
    # Fixes to the compiler and standard libary.
    prev.nim-unwrapped.overrideAttrs
    (attrs: { patches = attrs.patches ++ [ ./nim/genode.patch ]; });

  nimblePackages =
    # Packages from the Nimble flake with adjustments.
    let pkgs' = flake.inputs.nimble.overlay (final // pkgs') final;
    in pkgs'.nimblePackages.extend (_: prev: {

      genode = prev.genode.overrideAttrs (attrs: rec {
        version = "20.11.1";
        src = fetchgit {
          inherit (attrs.src) url;
          rev = "v${version}";
          sha256 = "0i78idsrgph0g2yir6niar7v827y6qnmd058s6mpvp091sllvlv8";
        };
      });

    });

  openssl =
    overrideHost { static = true; } # shared library comes out stupid big
    (overrideAttrsHost (attrs: {
      outputs = [ "out" ]
        ++ builtins.filter (x: x != "bin" && x != "out") attrs.outputs;
      patches = attrs.patches or [ ] ++ [ ./openssl/genode.patch ];
      configureScript = {
        x86_64-genode = "./Configure genode-x86_64";
        aarch64-genode = "./Configure genode-aarch64";
      }.${stdenv.hostPlatform.system} or (throw
        "Not sure what configuration to use for ${stdenv.hostPlatform.config}");
      configureFlags = attrs.configureFlags ++ [ "no-devcryptoeng" ];
      postInstall =
        "rm $out/bin/c_rehash"; # eliminate the perl runtime dependency
    }) prev.openssl);

  patchelf = addPatchesTarget [
    ./patchelf/dynstr.patch
    # Patch to fix a bug in rewriting the .dynstr section.
  ] prev.patchelf;

  rsync = overrideHost {
    enableACLs = false;
    popt = null;
  } (overrideAttrsHost (_: { outputs = [ "out" "man" ]; }) rsync);

  solo5-tools = callPackage ./solo5-tools { };

  stdenv = overrideHost (old: {
    extraNativeBuildInputs = old.extraNativeBuildInputs
      ++ [ final.buildPackages.erisPatchHook ];
  }) prev.stdenv;

  tor = overrideAttrsHost (attrs: {
    patches = attrs.patches or [ ] ++ [
      ./tor/genode.patch
      # We don't do users and groups here.
    ];
    postPatch = null; # Avoid torsocks patching
  }) prev.tor;

  zlib = overrideAttrsHost (attrs: {
    postInstall = attrs.postInstall or "" + ''
      pushd ''${!outputLib}/lib
      find . -type l -delete
      mv libz.so.* libz.so
      popd
    '';
  }) prev.zlib;

  zstd = let
    static = true;
    legacySupport = false;
  in overrideAttrsHost (_: rec {
    cmakeFlags = lib.attrsets.mapAttrsToList
      (name: value: "-DZSTD_${name}:BOOL=${if value then "ON" else "OFF"}") {
        BUILD_SHARED = !static;
        BUILD_STATIC = static;
        PROGRAMS_LINK_SHARED = !static;
        LEGACY_SUPPORT = legacySupport;
        BUILD_TESTS = doCheck;
      };
    doCheck = stdenv.hostPlatform == stdenv.buildPlatform;
  }) prev.zstd;

}
