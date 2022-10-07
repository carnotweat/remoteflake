{ genodePackages, symlinkJoin }:
let inherit (genodePackages) genodeSources;
in symlinkJoin {
  name = "posix";
  paths = with genodePackages; [ libc posix ];
  postBuild = ''
    local headerDir="''${!outputDev}/include"
    mkdir -p "$headerDir"
    pushd ${genodeSources.ports.libc}/*
    cp -r \
      include/libc/* \
      include/openlibm/* \
      ${genodeSources}/repos/libports/include/libc \
      "$headerDir"
    for spec in ${toString genodeSources.specs}; do
      dir=include/spec/$spec/libc
      if [ -d $dir ]; then
        cp -r $dir/* "$headerDir"
      fi
    done
    popd
  '';
}
