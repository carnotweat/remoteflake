# Shameless plagiarism of Blitz's toolchain expression:
# https://github.com/blitz/genode-nix

{ lib, stdenv, fetchurl, ncurses5, expat, makeWrapper, wrapCC }:

let
  cc = stdenv.mkDerivation rec {
    pname = "genode-toolchain";
    version = "19.05";

    src = fetchurl ({
      x86_64-linux = {
        url =
          "mirror://sourceforge/project/genode/${pname}/${version}/${pname}-${version}-x86_64.tar.xz";
        sha256 = "036czy21zk7fvz1y1p67q3d5hgg8rb8grwabgrvzgdsqcv2ls6l9";
      };
    }.${stdenv.buildPlatform.system} or (throw
      "cannot install Genode toolchain on this platform"));

    preferLocalBuild = true;

    nativeBuildInputs = [ makeWrapper ];

    phases = [ "unpackPhase" "fixupPhase" ];

    dontStrip = true;
    dontPatchELF = true;

    libPath = lib.makeLibraryPath [ "$out" stdenv.cc.cc expat ncurses5 ];

    unpackPhase = ''
      mkdir $out
      tar xf $src --strip-components=5 -C $out
    '';

    preFixup = ''
      for p in $(find "$out" -type f -executable); do
        if isELF "$p"; then
          echo "Patchelfing $p"
          patchelf "$p"
          patchelf --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) "$p"  || true
          patchelf --set-rpath ${libPath}  "$p" || true
        fi
      done
      pushd $out/bin
      for BIN in $out/bin/genode-aarch64-*; do
        makeWrapper ''${BIN} aarch64-unknown-genode-''${BIN#$out/bin/genode-aarch64-}
      done
      for BIN in $out/bin/genode-arm-*; do
        makeWrapper ''${BIN} arm-unknown-genode-''${BIN#$out/bin/genode-arm-}
      done
      for BIN in $out/bin/genode-riscv-*; do
        makeWrapper ''${BIN} riscv-unknown-genode-''${BIN#$out/bin/genode-riscv-}
      done
      for BIN in $out/bin/genode-x86-*; do
        makeWrapper ''${BIN} i686-unknown-genode-''${BIN#$out/bin/genode-x86-}
        makeWrapper ''${BIN} x86_64-unknown-genode-''${BIN#$out/bin/genode-x86-}
      done
      popd
      ln -s $out/aarch64-none-elf $out/aarch64-unknown-genode
      ln -s $out/arm-none-eabi $out/arm-unknown-genode
      ln -s $out/riscv64-unknown-elf $out/riscv-unknown-genode
      ln -s $out/x86_64-pc-elf $out/x86_64-unknown-genode
    '';
  } // {
    # Needed by the GCC wrapper.
    langC = true;
    langCC = true;
    isGNU = true;
    targetPrefix = {
      aarch64-genode = "genode-arm-";
      x86_64-genode = "genode-x86-";
    }.${stdenv.targetPlatform.system} or null;
  };

  wrapped = wrapCC cc;

  wrapped' = wrapped.overrideAttrs (_: { inherit (cc) src targetPrefix; });

in wrapped'
