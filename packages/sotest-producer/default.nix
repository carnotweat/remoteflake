{ lib, stdenv, fetchgit, tup }:

stdenv.mkDerivation rec {
  pname = "sotest-producer";
  version = "0.2.0";

  nativeBuildInputs = [ tup ];

  src = fetchgit {
    url = "https://git.sr.ht/~ehmry/genode-sotest-producer";
    rev = "eed74df5977b01809893efaa84e7ad6d207423d2";
    sha256 = "1cf08jk2y6advlk9hczzklc220195fj3ybjvd16y8v1sfpfg84lx";
  };

  installPhase = "install -Dm755 {.,$out/bin}/sotest-harness";

  meta = with lib; {
    license = "LicenseRef-Genode.txt";
    maintainers = [ maintainers.ehmry ];
  };

}
