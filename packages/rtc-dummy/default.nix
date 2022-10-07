{ lib, stdenv, fetchgit, tup }:

stdenv.mkDerivation rec {
  pname = "rtc_dummy";
  version = "0.0.0";

  nativeBuildInputs = [ tup ];

  src = fetchgit {
    url = "https://git.sr.ht/~ehmry/rtc-dummy";
    rev = "42c8a0453853816b99c56fc7bde8e1039b2ec0a7";
    sha256 = "1rs081cxwbf2sra383j7r9xrg12gqf591hiyb4h2h3qa9pc6p602";
  };

  installPhase = "install -Dm755 ./rtc-dummy $out/rtc_drv";

  meta = with lib; {
    license = licenses.agpl3;
    maintainers = [ maintainers.ehmry ];
  };

}
