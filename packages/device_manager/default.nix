{ lib, stdenv, fetchgit, nim, nimblePackages }:

stdenv.mkDerivation rec {
  pname = "device_manager";
  version = "0.0";
  outputs = [ "out" "dhall" ];

  src = fetchgit {
    url = "https://git.sr.ht/~ehmry/${pname}";
    rev = "4ff7d47b83255a437d862d16b8424a3c05e3eab1";
    sha256 = "0bmcl693w34ayrw77c6gicph43yfjfm800jwj57ryshr9fdh88dq";
  };

  nimFlags = with nimblePackages;
    map (lib: "--path:${lib}/src") [ genode ] ++ [ "-d:posix" ];

  nativeBuildInputs = [ nim ];

  preHook = ''
    export HOME="$NIX_BUILD_TOP"
  '';

  buildPhase = ''
    runHook preBuild
    nim cpp $nimFlags src/$pname
    runHook postBuild
  '';

  installPhase = ''
    install -Dt $out/bin src/$pname
    install -Dt $dhall config/package.dhall
  '';
}
