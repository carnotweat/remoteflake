{
  name = "ahci";
  machine = { pkgs, ... }: {
    fileSystems."/".block = {
      driver = "ahci";
      device = 0;
      partition = 1;
    };
    genode.core.storeBackend = "fs";
    genode.init.children.hello = {
      package = pkgs.hello;
      configFile = ./hello.dhall;
    };
  };
  testScript = ''
    start_all()
    machine.wait_until_serial_output("Hello, world!")
  '';
}
