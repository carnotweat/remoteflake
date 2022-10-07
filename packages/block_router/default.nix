{ lib, stdenv, fetchgit, tup }:

stdenv.mkDerivation rec {
  pname = "block_router";
  version = "0.1.2";

  nativeBuildInputs = [ tup ];

  src = fetchgit {
    url = "https://git.sr.ht/~ehmry/block_router";
    rev = "v" + version;
    sha256 = "sha256-X3rVHBwvEG6ove0bE6sIUcFcfXhSHYCBCOjhEp/ETsc=";
  };

  installPhase = "install -Dm755 {.,$out}/block_router";

  meta = with lib; {
    license = licenses.agpl3;
    maintainers = [ maintainers.ehmry ];
  };

}
