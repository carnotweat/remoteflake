{ config, pkgs, lib, ... }:

with lib;
let
  utils = import ../lib {
    inherit (config.nixpkgs) system localSystem crossSystem;
    inherit pkgs;
  };
in {
  genode.core = {
    prefix = "hw-virt_qemu";
    supportedSystems = [ "aarch64-genode" ];
    basePackages = with pkgs.genodePackages; [ base-hw-virt_qemu rtc-dummy ];
  };

  genode.core = {

    initrd = "${config.genode.core.image}/image.elf";

    image = utils.hwImage "0xffffffc000000000" "0x40000000"
      pkgs.genodePackages.base-hw-virt_qemu config.system.name { }
      config.system.build.configFile;

  };

}
