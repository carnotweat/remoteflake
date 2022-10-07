# Builds a compressed EFI System Partition image
{ config, pkgs }:

let
  grub' = pkgs.buildPackages.grub2_efi;

  # Name used by UEFI for architectures.
  targetArch = if pkgs.stdenv.isi686 || config.boot.loader.grub.forcei686 then
    "ia32"
  else if pkgs.stdenv.isx86_64 then
    "x64"
  else if pkgs.stdenv.isAarch64 then
    "aa64"
  else
    throw "Unsupported architecture";

in pkgs.stdenv.mkDerivation {
  name = "esp.img.zst";

  nativeBuildInputs = with pkgs.buildPackages; [ grub' dosfstools mtools zstd ];

  MODULES = [
    "configfile"
    "efi_gop"
    "efi_uga"
    "fat"
    "gzio"
    "multiboot"
    "multiboot2"
    "normal"
    "part_gpt"
    "search"
  ];

  buildCommand = ''
    img=tmp.raw
    bootdir=./espRoot/boot/
    grubdir=./espRoot/boot/grub
    efidir=./espRoot/EFI/boot

    mkdir -p $bootdir $efidir $grubdir

    cat <<EOF > embedded.cfg
    insmod configfile
    insmod efi_gop
    insmod efi_uga
    insmod fat
    insmod normal
    insmod part_gpt
    insmod search_fs_uuid
    search --set=root --label EFIBOOT
    set prefix=($root)/boot/grub
    configfile /boot/grub/grub.cfg
    EOF

    grub-script-check embedded.cfg

    ${grub'}/bin/grub-mkimage \
      --config=embedded.cfg \
      --output=$efidir/boot${targetArch}.efi \
      --prefix=/sigil/grub \
      --format=${grub'.grubTarget} \
      $MODULES

    cat > extraPrepareConfig.sh <<< '${config.boot.loader.grub.extraPrepareConfig}'
    substituteInPlace extraPrepareConfig.sh \
      --replace '${pkgs.coreutils}' '${pkgs.buildPackages.coreutils}' \
      --replace '@bootPath@' "$bootdir"
    source extraPrepareConfig.sh

    cat <<EOF > $grubdir/grub.cfg
    set timeout=3
    set default=0
    set gfxmode=auto
    set gfxpayload=auto

    ${config.boot.loader.grub.extraEntries}
    EOF

    grub-script-check $grubdir/grub.cfg


    # Make the ESP image twice as large as necessary
    imageBytes=$(du --summarize --block-size=4096 --total espRoot | tail -1 | awk '{ print int($1 * 8192) }')

    truncate --size=$imageBytes $img
    mkfs.vfat -n EFIBOOT --invariant $img
    mcopy -sv -i $img espRoot/* ::
    fsck.vfat -nv $img

    zstd --verbose --no-progress ./$img -o $out
  '';
}
