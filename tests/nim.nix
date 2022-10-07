{
  name = "nim";
  machine = { pkgs, ... }: {
    genode.init.children.test_nim = let
      testNim = with pkgs;
        stdenv.mkDerivation {
          pname = "test-nim";
          inherit (nim-unwrapped) version;
          nativeBuildInputs = [ nim ];
          dontUnpack = true;
          dontConfigure = true;
          buildPhase = ''
            export HOME=$NIX_BUILD_TOP
            cat << EOF > test_nim.nim
            echo "Hello Nim world!"
            EOF

            nim cpp -d:posix -d:release --gc:orc test_nim
          '';

          installPhase = ''
            install -Dt $out/bin test_nim
          '';
        };
    in {
      package = testNim;
      extraInputs = with pkgs.genodePackages; [ libc stdcxx ];
      configFile = builtins.toFile "nim.dhall" ''
        let Sigil = env:DHALL_SIGIL

        let Init = Sigil.Init

        let Child = Init.Child

        let Libc = Sigil.Libc

        in  λ(binary : Text) →
              Child.flat
                Child.Attributes::{
                , binary
                , exitPropagate = True
                , resources = Sigil.Init.Resources::{
                  , caps = 500
                  , ram = Sigil.units.MiB 10
                  }
                , config = Libc.toConfig Libc.default
                }
      '';
    };
  };

  testScript = ''
    start_all()
    machine.wait_until_serial_output("Hello Nim world!")
  '';
}
