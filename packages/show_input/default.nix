{ lib, stdenv, fetchgit, tup }:
stdenv.mkDerivation rec {
  pname = "show_input";
  version = "0.2.0";

  src = fetchgit {
    url = "https://git.sr.ht/~ehmry/show_input";
    rev = "v" + version;
    sha256 = "sha256-yW9DaQBClAtPyo62oFPn+eu+y5VKBFPl+dmUMPaFi1A=";
  };

  nativeBuildInputs = [ tup ];

  installPhase = "install -Dm755 {.,$out}/${pname}";

  meta = with lib; {
    license = licenses.agpl3;
    maintainers = [ maintainers.ehmry ];
  };

}
