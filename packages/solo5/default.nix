{ lib, stdenv, buildPackages, fetchurl, solo5-tools }:

# WARNING: recursive make ahead

let version = "0.6.7";
in stdenv.mkDerivation {
  pname = "solo5";
  inherit version;
  outputs = [ "out" "dev" "tests" ];

  nativeBuildInputs = [ solo5-tools ];

  src = fetchurl {
    url =
      "https://github.com/Solo5/solo5/releases/download/v${version}/solo5-v${version}.tar.gz";
    sha256 = "05k9adg3440zk5baa6ry8z5dj8d8r8hvzafh2469pdgcnr6h45gr";
  };

  enableParallelBuilding = true;

  patches = [
    ./genode.patch
    ./elftool.patch
    ./test_time.patch
    ./misleading-indentation.patch
  ];

  configurePhase = with stdenv; ''
    runHook preConfigure
    sh configure.sh
    ${lib.optionalString (hostPlatform.isAarch64) "rm -fr tests/test_fpu"}
    rm -fr tests/test_tls
    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall
    install -Dt $out/lib bindings/genode/solo5.lib.so
    mkdir $dev
    cp -r include/solo5 $dev/include
    for test in tests/*/*.genode; do
      install -D $test $tests/bin/solo5-$(basename $test .genode)
    done
    runHook postInstall
  '';

  meta = with lib; {
    description = "Sandboxed execution environment.";
    homepage = "https://github.com/solo5/solo5";
    license = licenses.isc;
    maintainers = [ maintainers.ehmry ];
  };

}
