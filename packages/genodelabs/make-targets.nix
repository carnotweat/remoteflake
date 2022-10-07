# This file contains overrides necessary to build some Make targets.

{ buildPackages, genodePackages, ports }:

{
  ping.targets = [ "app/ping" ];

  nic_dump.targets = [ "server/nic_dump" ];

  test-pci.targets = [ "test/pci" ];

  test-rtc.targets = [ "test/rtc" ];

  test-vmm_x86 = {
    targets = [ "test/vmm_x86" ];
    patches = [ ./patches/test-vmm_x86.patch ];
  };

  vbox5 = {
    targets = [ "virtualbox5" ];
    nativeBuildInputs = with buildPackages; [ iasl yasm ];
    portInputs = with ports; [ libc libiconv qemu-usb stdcxx virtualbox5 ];
  };

}
