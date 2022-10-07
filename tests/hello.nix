{
  name = "hello";
  machine = { pkgs, ... }: {
    genode.init.verbose = true;
    genode.init.children.hello = {
      package = pkgs.hello;
      configFile = ./hello.dhall;
    };
  };
  testScript = ''
    start_all()
    machine.wait_until_serial_output("child \"init\" exited with exit value 0")
  '';
}
