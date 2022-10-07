{
  name = "log";
  machine = { pkgs, ... }: {

    genode.init.children.log = {
      package = pkgs.genodePackages.test-log;
      configFile = pkgs.writeText "test-log.dhall" ''
        let Sigil = env:DHALL_SIGIL

        let Child = Sigil.Init.Child

        in  λ(binary : Text) →
              Child.flat
                Child.Attributes::{
                , binary
                , exitPropagate = True
                , resources = Sigil.Init.Resources::{
                  , caps = 500
                  , ram = Sigil.units.MiB 10
                  }
                }
      '';
    };
  };
  testScript = ''
    start_all()
    machine.wait_until_serial_output("Test done.")
  '';
}
