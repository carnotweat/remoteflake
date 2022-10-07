{ config, pkgs, lib, ... }:

with lib;
let
  utils = import ../lib {
    inherit (config.nixpkgs) system localSystem crossSystem;
    inherit pkgs;
  };
in {
  genode.core = {
    prefix = "hw-pc-";
    supportedSystems = [ "x86_64-genode" ];
    basePackages = with pkgs.genodePackages; [ base-hw-pc rtc_drv ];
  };

  genode.core = {

    initrd = "${config.genode.core.image}/image.elf";

    image = utils.hwImage "0xffffffc000000000" "0x00200000"
      pkgs.genodePackages.base-hw-pc config.system.name { }
      config.system.build.configFile;

  };

}
