{ lib, stdenv, buildPackages, fetchFromGitHub }:

let
  ARCH = if stdenv.isx86_32 then
    "x86_32"
  else if stdenv.isx86_64 then
    "x86_64"
  else
    null;
in if ARCH == null then
  null
else

  buildPackages.stdenv.mkDerivation rec {
    # Borrow the build host compiler,
    pname = "NOVA";
    version = "r10";
    inherit ARCH;

    src = fetchFromGitHub {
      owner = "alex-ab";
      repo = "NOVA";
      rev = "af931a15fc6b032615f076e946b6026a31dbacaf";
      sha256 = "1phx5dx8bqw4ibz4kva1k7vidbp21djjch5r9lilbl4bcpj4kd17";
    };

    enableParallelBuilding = true;

    makeFlags = [ "--directory build" ];

    preInstall = "export INS_DIR=$out";

    meta = with lib;
      src.meta // {
        description = "Microhypervisor";
        homepage = "http://hypervisor.org/";
        platforms = platforms.x86;
        license = licenses.gpl2;
        maintainers = [ maintainers.ehmry ];
      };

  }
