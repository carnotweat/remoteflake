{
  name = "usb";
  machine = { pkgs, ... }: {
    genode.core.storeBackend = "fs";
    hardware.genode.usb.enable = true;
    hardware.genode.usb.storage.enable = true;
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
