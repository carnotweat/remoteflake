{ final, prev }:

let
  addPatches = patches': drv:
    (drv.overrideAttrs
      ({ patches ? [ ], ... }: { patches = patches ++ patches'; }));

  libraries = prev.llvmPackages_11.libraries.extend (final': prev': {

    libcxxabi = prev'.libcxxabi.overrideAttrs ({ cmakeFlags, ... }: {
      cmakeFlags = cmakeFlags ++ [ "-DLIBCXXABI_ENABLE_THREADS=OFF" ];
    });

    libcxx = prev'.libcxx.overrideAttrs ({ cmakeFlags, patches ? [ ], ... }: {
      patches = patches ++ [ ./libcxx-genode.patch ];
    });

  });

  tools = prev.llvmPackages_11.tools.extend (final': prev': {

    llvm = addPatches [ ./llvm-genode.patch ] prev'.llvm;

    lld = addPatches [ ./lld-genode.patch ] prev'.lld;

    clang-unwrapped = prev'.clang-unwrapped.overrideAttrs
      ({ patches ? [ ], postPatch, ... }: {
        patches = patches ++ [ ./clang-genode.patch ];
        postPatch = postPatch + ''
          sed -i -e 's/lgcc_s/lgcc_eh/' lib/Driver/ToolChains/*.cpp
        '';
      });

    lldClang = prev'.lldClang.override
      (with final.genodePackages; {
        gccForLibs = genodeSources.toolchain.cc;
        nixSupport = {
          cc-cflags = [
            "--gcc-toolchain=${genodeSources.toolchain.cc}"
            "--sysroot=${genodeSources.genodeBase}"
            "-I${genodeSources.genodeBase}/include"
            "-L${genodeSources.genodeBase}"
          ];
          libcxx-ldflags = [ "${stdcxx}/lib/stdcxx.lib.so" ];
        };
      });

    lldClangNoLibcxx = prev'.lldClangNoLibcxx.override
      (with final.genodePackages; {
        nixSupport = {
          cc-cflags = [ "--sysroot=${genodeSources.genodeBase}" ];
          cc-ldflags = [ "-L${genodeSources.genodeBase}" ];
        };
      });

  });

in { inherit libraries tools; } // libraries // tools # awkward
