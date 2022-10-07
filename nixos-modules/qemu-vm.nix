{ config, lib, pkgs, ... }:

with lib;
with import ../tests/lib/qemu-flags.nix { inherit pkgs; };

let

  qemu = pkgs.buildPackages.buildPackages.qemu;

  cfg = config.virtualisation;

  consoles = lib.concatMapStringsSep " " (c: "console=${c}") cfg.qemu.consoles;

  efiPrefix = if (pkgs.stdenv.isi686 || pkgs.stdenv.isx86_64) then
    "${pkgs.buildPackages.buildPackages.OVMF.fd}/FV/OVMF"
  else if pkgs.stdenv.isAarch64 then
    "${pkgs.buildPackages.buildPackages.OVMF.fd}/FV/AAVMF"
  else
    throw "No EFI firmware available for platform";
  efiFirmware = "${efiPrefix}_CODE.fd";

  # Shell script to start the VM.
  startVM = ''
    #! ${pkgs.buildPackages.runtimeShell}
  '' + lib.optionalString (config.virtualisation.diskImage != null) ''
    NIX_DISK_IMAGE=$(readlink -f ''${NIX_DISK_IMAGE:-${config.virtualisation.diskImage}})

    if ! test -w "$NIX_DISK_IMAGE"; then
      ${qemu}/bin/qemu-img create -f qcow2 -b $NIX_DISK_IMAGE $TMPDIR/disk.img || exit 1
      NIX_DISK_IMAGE=$TMPDIR/disk.img
    fi

    if ! test -e "$NIX_DISK_IMAGE"; then
        ${qemu}/bin/qemu-img create -f qcow2 "$NIX_DISK_IMAGE" \
          ${toString config.virtualisation.diskSize}M || exit 1
    fi

  '' + ''
    # Create a directory for storing temporary data of the running VM.
    if [ -z "$TMPDIR" -o -z "$USE_TMPDIR" ]; then
        TMPDIR=$(mktemp -d nix-vm.XXXXXXXXXX --tmpdir)
    fi

    # Start QEMU.
    set -v
    exec ${qemuBinary qemu} \
        -name ${config.system.name} \
        -m ${toString config.virtualisation.memorySize} \
        -smp ${toString config.virtualisation.cores} \
        ${toString config.virtualisation.qemu.options} \
        ${
          if config.hardware.genode.usb.storage.enable then
            "-drive id=usbdisk,if=none,file=$NIX_DISK_IMAGE -device usb-storage,drive=usbdisk"
          else
            "$NIX_DISK_IMAGE"
        } \
        $QEMU_OPTS \
        "$@"
  '';

in {
  options = {

    virtualisation.memorySize = mkOption {
      default = 384;
      description = ''
        Memory size (M) of virtual machine.
      '';
    };

    virtualisation.diskSize = mkOption {
      default = 512;
      description = ''
        Disk size (M) of virtual machine.
      '';
    };

    virtualisation.diskImage = mkOption {
      type = with types; nullOr path;
      default = null;
      description = ''
        Path to the disk image containing the root filesystem.
        The image will be created on startup if it does not
        exist.
      '';
    };

    virtualisation.emptyDiskImages = mkOption {
      default = [ ];
      type = types.listOf types.int;
      description = ''
        Additional disk images to provide to the VM. The value is
        a list of size in megabytes of each disk. These disks are
        writeable by the VM.
      '';
    };

    virtualisation.graphics = mkOption {
      default = true;
      description = ''
        Whether to run QEMU with a graphics window, or in nographic mode.
        Serial console will be enabled on both settings, but this will
        change the preferred console.
      '';
    };

    virtualisation.cores = mkOption {
      default = 1;
      type = types.int;
      description = ''
        Specify the number of cores the guest is permitted to use.
        The number can be higher than the available cores on the
        host system.
      '';
    };

    virtualisation.pathsInNixDB = mkOption {
      default = [ ];
      description = ''
        The list of paths whose closure is registered in the Nix
        database in the VM.  All other paths in the host Nix store
        appear in the guest Nix store as well, but are considered
        garbage (because they are not registered in the Nix
        database in the guest).
      '';
    };

    virtualisation.vlans = mkOption {
      default = [ ];
      example = [ 1 2 ];
      description = ''
        Virtual networks to which the VM is connected.  Each
        number <replaceable>N</replaceable> in this list causes
        the VM to have a virtual Ethernet interface attached to a
        separate virtual network on which it will be assigned IP
        address
        <literal>192.168.<replaceable>N</replaceable>.<replaceable>M</replaceable></literal>,
        where <replaceable>M</replaceable> is the index of this VM
        in the list of VMs.
      '';
    };

    virtualisation.writableStore = mkOption {
      default = true; # FIXME
      description = ''
        If enabled, the Nix store in the VM is made writable by
        layering an overlay filesystem on top of the host's Nix
        store.
      '';
    };

    virtualisation.writableStoreUseTmpfs = mkOption {
      default = true;
      description = ''
        Use a tmpfs for the writable store instead of writing to the VM's
        own filesystem.
      '';
    };

    networking.primaryIPAddress = mkOption {
      default = "";
      internal = true;
      description = "Primary IP address used in /etc/hosts.";
    };

    virtualisation.qemu = {
      options = mkOption {
        type = types.listOf types.unspecified;
        default = [ ];
        example = [ "-vga std" ];
        description = "Options passed to QEMU.";
      };

      consoles = mkOption {
        type = types.listOf types.str;
        default = let consoles = [ "${qemuSerialDevice},115200n8" "tty0" ];
        in if cfg.graphics then consoles else reverseList consoles;
        example = [ "console=tty1" ];
        description = ''
          The output console devices to pass to the kernel command line via the
          <literal>console</literal> parameter, the primary console is the last
          item of this list.

          By default it enables both serial console and
          <literal>tty0</literal>. The preferred console (last one) is based on
          the value of <option>virtualisation.graphics</option>.
        '';
      };

      nics = mkOption {
        description = "QEMU network devices.";
        default = { };
        type = with lib.types;
          attrsOf (submodule {
            options = {
              netdev = mkOption {
                type = submodule {
                  options = {
                    kind = mkOption {
                      type = str;
                      default = "user";
                    };
                    settings = mkOption {
                      type = attrsOf str;
                      default = { };
                    };
                  };
                };
              };
              device = mkOption {
                type = submodule {
                  options = {
                    kind = mkOption {
                      type = str;
                      default = "virtio-net-pci";
                    };
                    settings = mkOption {
                      type = attrsOf str;
                      default = { };
                    };
                  };
                };
              };
            };
          });
      };

      diskInterface = mkOption {
        default = "ahci";
        example = "usb";
        type = types.enum [ "ahci" "usb" "virtio" ];
        description = "The interface used for the virtual hard disks.";
      };

      kernel = mkOption {
        type = types.path;
        description = "Guest kernel.";
      };

      initrd = mkOption {
        type = types.path;
        description = "Guest initrd.";
      };

      cmdline = mkOption {
        type = types.str;
        description = "Command line options to pass to guest.";
      };

    };

    virtualisation.useBootLoader = mkOption {
      default = false;
      description = ''
        If enabled, the virtual machine will be booted using the
        regular boot loader (i.e., GRUB 1 or 2).  This allows
        testing of the boot loader.  If
        disabled (the default), the VM directly boots the NixOS
        kernel and initial ramdisk, bypassing the boot loader
        altogether.
      '';
    };

    virtualisation.useEFIBoot = mkOption {
      default = false;
      description = ''
        If enabled, the virtual machine will provide a EFI boot
        manager.
        useEFIBoot is ignored if useBootLoader == false.
      '';
    };

    virtualisation.efiVars = mkOption {
      default = "./${config.system.name}-efi-vars.fd";
      description = ''
        Path to nvram image containing UEFI variables.  The will be created
        on startup if it does not exist.
      '';
    };

    virtualisation.bios = mkOption {
      default = null;
      type = types.nullOr types.package;
      description = ''
        An alternate BIOS (such as <package>qboot</package>) with which to start the VM.
        Should contain a file named <literal>bios.bin</literal>.
        If <literal>null</literal>, QEMU's builtin SeaBIOS will be used.
      '';
    };

  };

  config = {

    # FIXME: Consolidate this one day.
    virtualisation.qemu.options = mkMerge [
      (mkIf cfg.useEFIBoot [
        "-drive if=pflash,format=raw,unit=0,readonly,file=${efiFirmware}"
        "-drive if=pflash,format=raw,unit=1,file=$NIX_EFI_VARS"
      ])
      (mkIf (cfg.bios != null) [ "-bios ${cfg.bios}/bios.bin" ])
      (mkIf (!cfg.graphics) [ "-nographic" ])
      (let
        toFlags = bind:
          { kind, settings }:
          lib.strings.concatStringsSep "," ([ "${kind},${bind}" ]
            ++ (lib.attrsets.mapAttrsToList (k: v: "${k}=${v}") settings));
      in lib.attrsets.mapAttrsToList (id: nic: [
        "-netdev ${toFlags "id=${id}" nic.netdev}"
        "-device ${toFlags "netdev=${id}" nic.device}"
      ]) cfg.qemu.nics)
    ];

    system.build.vm = pkgs.runCommand "nixos-vm" { preferLocalBuild = true; } ''
      mkdir -p $out/bin
      ln -s ${
        pkgs.writeScript "run-nixos-vm" startVM
      } $out/bin/run-${config.system.name}-vm
    '';

  };
}
