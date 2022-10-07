{ lib, stdenv, fetchgit, tup }:
stdenv.mkDerivation rec {
  pname = "nic_bus";
  version = "2.1";

  src = fetchgit {
    url = "https://git.sr.ht/~ehmry/nic_bus";
    rev = "v" + version;
    sha256 = "sha256-NuXbkBgZx1DZ3yWH3iOJZ6oMVpKV1Cc2ZfqQzTM16C8=";
  };

  nativeBuildInputs = [ tup ];

  installPhase = "install -Dm755 {.,$out}/${pname}";

  meta = with lib; {
    license = licenses.agpl3;
    maintainers = [ maintainers.ehmry ];
  };

}
