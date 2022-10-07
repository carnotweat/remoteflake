{ config, lib, pkgs, ... }:
with lib; {

  options = {

    block.partitions = let
      mkPartitionOption = { description, gptType }: {
        image = lib.mkOption {
          type = types.path;
          inherit description;
        };
        gptType = lib.mkOption {
          type = types.str;
          default = gptType;
        };
        guid = lib.mkOption { type = types.str; };
      };
    in {
      esp = mkPartitionOption {
        description = "EFI system partition";
        gptType = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b";
      };
      store = mkPartitionOption {
        description = "ERIS store partition";
        gptType = lib.uuidFrom "ERIS ISO9660";
      };
    };

    fileSystems = lib.mkOption {
      type = types.attrsOf (types.submodule {
        options.block = {

          device = lib.mkOption { type = types.int; };

          driver = lib.mkOption { type = types.enum [ "ahci" "usb" ]; };

          partition = lib.mkOption { type = types.ints.positive; };

        };
      });
    };

  };

  config = {

    assertions = [{
      assertion = config.fileSystems."/".fsType == "ext2";
      message = "The only supported fsType is EXT2";
    }];

    block.partitions.esp = rec {
      image = import ./lib/make-esp-fs.nix { inherit config pkgs; };
      guid = lib.uuidFrom (toString image);
    };

    hardware.genode.ahci.enable =
      any (fs: fs.block.driver == "ahci") (attrValues config.fileSystems);

    hardware.genode.usb.storage.enable = lib.mkDefault
      (any (fs: fs.block.driver == "usb") (attrValues config.fileSystems));
  };

}
