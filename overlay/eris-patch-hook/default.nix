{ lib, stdenv, patchelf, nimblePackages }:

stdenv.mkDerivation {
  name = "eris_patch";
  nativeBuildInputs = with nimblePackages; [ nim ];
  buildInputs = with nimblePackages; [ eris ];
  inherit patchelf;
  dontUnpack = true;
  nimFlags = [ "-d:release" ];
  buildPhase = ''
    HOME=$TMPDIR
    cp ${./eris_patch.nim} eris_patch.nim
    nim c $nimFlags eris_patch
  '';
  installPhase = "install -Dt $out/bin eris_patch";
  setupHook = ./eris_patch.sh;
}
