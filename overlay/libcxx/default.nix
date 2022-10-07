{ genodePackages, symlinkJoin }:
let inherit (genodePackages) genodeSources;
in symlinkJoin {
  name = "libcxx";
  paths = with genodePackages; [ stdcxx ];
  postBuild = ''
    local headerDir="''${!outputDev}/include"
    mkdir -p "$headerDir"
    pushd ${genodeSources.ports.stdcxx}/*
    cp -r \
      include/include/stdcxx/* \
      ${genodeSources}/repos/libports/include/stdcxx \
      "$headerDir"
    popd
  '';
}
