# This file specifies the output hashes of "Ports".
# Ports not listed here can still be prepared, but will result in a hash mismatch.

{ pkgs, worldSources }:
with pkgs;

{
  bash.hash = "sha256-Se03Eyh8grk+QGAXLGoig7oXqmHtAwtHJX54fCVHw+8=";
  binutils = {
    hash = "sha256-ERzYT3TjbK3fzRVN1UE7RM6XiPPeMKzkeulKx5IQa2o=";
    nativeBuildInputs = [ autoconf ];
  };
  coreutils.hash = "sha256-ZVlFfLghHcXxwwRsN5xw2bVdIvvXoCNj2oZniOlSXrg=";
  curl.hash = "sha256-5+nRKLrho9oO0XlzDO6ppZ2kLfWaIReY24YFYSQT7Xc=";
  # dde_bsd.hash = "sha256-KPA/ua3jETcHgWzhfhFm6ppds55Xi5YXJKDJvufJmU8=";
  dde_ipxe.hash = "sha256-rnMbramSDYBEjfSMoNpFcUQ4jfJh6SIHMtieSy9/Fe4=";
  dde_linux.hash = "sha256-DOPa+Bi/dV9NVSCQa0GOapQsNbZQBhZ4gtcTq3TiAGw=";
  dde_rump = {
    hash = "sha256-Wr5otGkWEa+5xImsFHQzwap5LckNEbyWA/7xbNcOreI=";
    nativeBuildInputs = [ subversion ];
    patches = [ ./patches/svn-trust-server-cert.patch ];
  };
  expat.hash = "sha256-KpeM2ySmf+Ojx1mAj9n8lfX7iHaa7w5MPPKZcn4GpTc=";
  gcc = {
    hash = "sha256-1AKjUbh8X5ips8pg0twpBTtc2qCVXGrbifJ/cf3yRcE=";
    nativeBuildInputs = [ autoconf264 autogen ];
    patches = [ ./patches/gcc-port.patch ];
  };
  gdb.hash = "sha256-YfVWDdXSRt7rHMvlMxIL5ikbHDe/e6ryTt3V7FfsJ4M=";
  gmp.hash = "sha256-ZOHMhhqMe8glpMEGg++uDjCxXksAXDiBKCchEPQKTCA=";
  jitterentropy.hash = "sha256-6KS732GxtUMz0xPYKtshdn039DgdJq11vTDQesZn4Ds=";
  jpeg.hash = "sha256-RLVnlrnYGrhqr3Feikoi/BNditCaKN0u3t9/UDpl2wQ=";
  libc = {
    hash = "sha256-/LX0uGiWLE+wNdbjNKr9CbzwqSPocHv5XBZuymJy1Gw=";
    nativeBuildInputs = [ gcc rpcsvc-proto ];
    patches = [ ./patches/libc-port.patch ];
  };
  libiconv.hash = "sha256-25YcW5zo1fE33ZolGQroR+KZO8wHEdN1QXa7+MhwS78=";
  libpng.hash = "sha256-hNmSWN4gEk4UIjzkGD4j5qFooMCVXLwcBeOeFumvh+4=";
  libssh.hash = "sha256-Z/1YdhISh2kqBjWiTOLkS+usoeeekJvAuYrVUgpxnQM=";
  lwip.hash = "sha256-RZsqy9iKiUfQzQOrPw2QWiKS5BkVbGe4HseF2DzeWeQ=";
  lz4.hash = "sha256-nydkAbexaqcKYDzp0TsECKMXyPaoY9rf3MAbU33VPrg=";
  mesa = {
    hash = "sha256-QPtvFMCG8ilwjzzcmXIvzswU9HB22M1DoEh+reI+qes=";
    nativeBuildInputs = [ python ];
  };
  mpc.hash = "sha256-MOs51NYXkNYxBG4d97/fMCx/iYzrNum8jHe3QujF24o=";
  mpfr.hash = "sha256-TSZCAHU7Vtuo9Pbi7v7oDV5Wc6YBVICriR4IbErYW4Q=";
  mupdf.hash = "sha256-6NX7zvOwReBBdz83RxGW2FJWUkqI/DTBkSOCqukidYs=";
  ncurses = {
    nativeBuildInputs = [ gcc mawk ncurses ];
    hash = "sha256-ufWjzMvV1LaDOthNSelpcFsd7Fa6LCXBm0eRXqeGs8M=";
  };
  openssl.hash = "sha256-epRL3SobYQ7xf8qwp6D5xu/Ms2T/LhUjjs273ywWRWg=";
  qemu-usb.hash = "sha256-F4ZXeH5sx3FOcD42zFOxKFMsqGookKdav1NJ7YgVw98=";
  seoul = {
    nativeBuildInputs = [ gcc python2 ];
    patches = [ ./patches/seoul-port.patch ];
    hash = "sha256-0TYtZrLGl3IOFpRjBRf0fkUXDd1aDlOF8RePfqoKEwA=";
  };
  stb.hash = "sha256-9LSH1i8jcEvjRAmTvgtK+Axy9hO7uiSzmSgBvs0zkTc=";
  stdcxx.hash = "sha256-4L9HUG1Wz3oCCuyyakRYOXzRna26JeeTngIS+jvJDBc=";
  virtualbox5 = {
    hash = "sha256-ERI+j2thvyMj+TJSHDdA9sOQdIxrXfNfMNJIa8VRE0M=";
    nativeBuildInputs = [ iasl libxslt unzip yasm ];
  };
  x86emu.hash = "sha256-QY6OL+cDVjQ67JItP1rS4ufPRGZf43AZtWxwza/0q0w=";
  xkcp = {
    extraRepos = [ worldSources ];
    hash = "sha256-oB7oFikCFnEtB/ZlV7Gayw3wNa0BU/vi7O5gfzeFGLg=";
    nativeBuildInputs = [ libxslt ];
    version = "cafc03";
  };
  zlib.hash = "sha256-j3JXN0f8thrPCvLhYHIPjbGa0t3iynQ/gO7KMlgljq0=";
}
