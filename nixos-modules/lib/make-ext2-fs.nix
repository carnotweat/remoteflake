{ config, lib, pkgs, extraInputs ? [ ], contents }:

let
  copyEris = lib.strings.concatMapStrings ({ source, target }: ''
    cp -a --reflink=auto "${source}" "./rootImage/${target}"
  '') contents;

in pkgs.stdenv.mkDerivation {
  name = "ext2-fs.img.zstd";

  nativeBuildInputs = with pkgs.buildPackages; [
    e2fsprogs.bin
    libfaketime
    perl
    fakeroot
    zstd
  ];

  buildCommand = ''
    img=temp.raw

    # Create nix/store before copying path
    mkdir -p ./rootImage/nix/store

    (
      GLOBIGNORE=".:.."
      shopt -u dotglob

      for f in ./files/*; do
          cp -a --reflink=auto -t ./rootImage/ "$f"
      done
    )

    mkdir ./rootImage/eris
    ${copyEris}

    # Make a crude approximation of the size of the target image.
    # If the script starts failing, increase the fudge factors here.
    numInodes=$(find ./rootImage | wc -l)
    numDataBlocks=$(du -s -c -B 4096 --apparent-size ./rootImage | tail -1 | awk '{ print int($1 * 1.10) }')
    bytes=$((2 * 4096 * $numInodes + 4096 * $numDataBlocks))
    echo "Creating an EXT2 image of $bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks)"

    truncate --size=$bytes $img

    faketime -f "1970-01-01 00:00:01" fakeroot mkfs.ext2 -L NIXOS_GENODE -U ${config.block.partitions.store.guid} -d ./rootImage $img

    export EXT2FS_NO_MTAB_OK=yes
    # I have ended up with corrupted images sometimes, I suspect that
    # happens when the build machine's disk gets full during the build.
    if ! fsck.ext2 -n -f $img; then
      echo "--- Fsck failed for EXT2 image of $bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks) ---"
      cat errorlog
      return 1
    fi

    echo "Resizing to minimum allowed size"
    resize2fs -M $img

    # And a final fsck, because of the previous truncating.
    fsck.ext2 -n -f $img

    # Compress to store
    zstd --verbose --no-progress ./$img -o $out
  '';
}
