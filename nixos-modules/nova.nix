{ config, pkgs, lib, ... }:

with lib;
let
  utils = import ../lib {
    inherit (config.nixpkgs) system localSystem crossSystem;
    inherit pkgs;
  };

  bootDir = pkgs.runCommand "${config.system.name}-bootdir" { } ''
    mkdir $out
    gz() {
      gzip --keep --to-stdout "$1" > "$2"
    }
    gz ${pkgs.genodePackages.genodeSources}/tool/boot/bender $out/bender.gz
    gz ${pkgs.genodePackages.NOVA}/hypervisor-x86_64 $out/hypervisor.gz
    gz ${config.genode.core.image}/image.elf $out/image.elf.gz
  '';

in {
  genode.core = {
    prefix = "nova-";
    supportedSystems = [ "x86_64-genode" ];
  };

  genode.core.image =
    utils.novaImage config.system.name { } config.system.build.configFile;

  genode.core.romModules = {
    "ld.lib.so" = "${pkgs.genodePackages.base-nova}/lib/ld.lib.so";
    timer_drv = "${pkgs.genodePackages.base-nova}/bin/timer_drv";
  };

  genode.core.storePaths =
    lib.optional (config.genode.core.storeBackend != "memory") bootDir;

  virtualisation.qemu.options =
    lib.optionals (!config.virtualisation.useBootLoader) [
      "-kernel '${pkgs.genodePackages.bender}/share/bender/bender'"
      "-initrd '${pkgs.genodePackages.NOVA}/hypervisor-x86_64 arg=iommu logmem novpid serial,${config.genode.core.image}/image.elf'"
    ];

  virtualisation.qemu.kernel =
    "${pkgs.genodePackages.bender}/share/bender/bender";

  virtualisation.qemu.initrd = "${pkgs.genodePackages.NOVA}/hypervisor-x86_64";

  virtualisation.qemu.cmdline =
    "arg=iommu logmem novpid serial,${config.genode.core.image}/image.elf";

  boot.loader.grub = {
    extraEntries = ''
      menuentry 'sigil-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}' {
        insmod gzio
        insmod multiboot2
        multiboot2 /boot/bender.gz serial_fallback
        module2 /boot/hypervisor.gz hypervisor iommu logmem novga novpid serial
        module2 /boot/image.elf.gz image.elf
      }
    '';
    extraFiles = {
      "bender.gz" = bootDir + "/bender.gz";
      "hypervisor.gz" = bootDir + "/hypervisor.gz";
      "image.elf.gz" = bootDir + "/image.elf.gz";
    };
  };

}
