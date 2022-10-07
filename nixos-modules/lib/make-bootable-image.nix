# Builds a compressed EFI System Partition image
{ config, lib, pkgs }:

let cfg = config.block.partitions;

in pkgs.stdenv.mkDerivation {
  name = "boot.qcow2";

  nativeBuildInputs = with pkgs.buildPackages.buildPackages; [
    qemu_test
    utillinux
    zstd
  ];

  disklabel = lib.uuidFrom config.system.nixos.label;

  buildCommand = ''
    img=./temp.raw

    # Pad the front of the image
    truncate --size=1M $img

    # Concatentenate the ESP
    espByteOffset=$(stat --printf='%s' $img)
    zstdcat ${cfg.esp.image} >> $img
    truncate --size=%1M $img

    # Concatenate the store
    storeByteOffset=$(stat --printf='%s' $img)
    zstdcat ${cfg.store.image} >> $img
    truncate --size=%1M $img

    # Pad the end of the image
    truncate --size=+1M $img

    imgBytes=$(stat --format=%s $img)

    # Create the partition table
    sectorSize=512
    sfdisk $img <<EOF
      label: gpt
      label-id: $disklabel
      start=$(( $storeByteOffset / $sectorSize )), uuid=${cfg.store.guid}, type=${cfg.store.gptType}
      start=$(( $espByteOffset / $sectorSize )), uuid=${cfg.esp.guid}, type=${cfg.esp.gptType}
    EOF
    sfdisk --reorder $img

    qemu-img convert -f raw -O qcow2 $img $out
  '';
}
