{ stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation rec {
  pname = "bender";
  version = "1.0.0-devel";

  src = fetchFromGitHub {
    owner = "blitz";
    repo = "bender";
    rev = "bb020b19fc8c6d31237ad3af3cee396add5ea938";
    sha256 = "01yp3x9d01cwn04c6w8pfmjazjpfzlhkvamzk44a05mx0k0dpk59";
  };

  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;

  nativeBuildInputs = [ cmake ];
  cmakeBuildType = "Release";
  cmakeFlags = [ "-DVERSION=${version}" ];
}
