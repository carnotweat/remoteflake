{ lib, stdenv, buildPackages, fetchurl }:

# WARNING: recursive make ahead

let version = "0.6.4";
in stdenv.mkDerivation {
  pname = "solo5-tools";
  inherit version;

  src = fetchurl {
    url =
      "https://github.com/Solo5/solo5/releases/download/v${version}/solo5-v${version}.tar.gz";
    sha256 = "sha256-7KyBXM0ZaG2WLoHpq6o/VoP8/qyclIEY9Hh/aLhcQlA=";
  };

  configurePhase = "sh configure.sh --only-tools";
  installPhase = "make install-tools DESTDIR=$out";

  meta = with lib; {
    description = "Sandboxed execution environment.";
    homepage = "https://github.com/solo5/solo5";
    license = licenses.isc;
    maintainers = [ maintainers.ehmry ];
  };

}
