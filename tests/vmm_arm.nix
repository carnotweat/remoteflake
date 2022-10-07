{ pkgs, localPackages, ... }:

{
  name = "vmm_arm";
  constraints = specs:
    with builtins;
    all (f: any f specs) [ (spec: spec == "aarch64") ];
  machine = {

    config = with localPackages;
      let
        dtb = runCommand "arm_v8.vmm.db" { buildInputs = [ dtc ]; }
          "dtc ${pkgs.genodeSources}/repos/os/src/server/vmm/spec/arm_v8/virt.dts > $out";
        linux = fetchurl {
          url = "http://genode.org/files/release-20.02/linux-arm64";
          hash = "sha256-H6FhNGgkApouy+PyjxrgAPnJSc4BIlWlpg+VhWiUI6o=";
        };
        initrd = fetchurl {
          url = "http://genode.org/files/release-20.02/initrd-arm64";
          hash = "sha256-iOKd2X2zgDIGeuLEDSSTLSw/Ywi7mDET36J1NAqgqls=";
        };

        guest = writeText "guest.dhall" ''
          { dtb = "${dtb}",  linux = "${linux}", initrd = "${initrd}" }
        '';

      in "${./vmm_arm.dhall} ${guest}";

    extraInputs = with pkgs;
      let
        vmm' = genodeSources.buildUpstream {
          name = "vmm_arm";
          targets = [ "server/vmm" ];
          KERNEL = "hw";
        };
      in [ vmm' ] ++ map genodeSources.depot [
        "log_terminal"
        "nic_router"
        "terminal_crosslink"
      ] ++ map genodeSources.make [ "test/terminal_expect_send" ];
  };

  testScript = ''
    start_all()
    machine.wait_until_serial_output("linuxrc")
  '';
}
