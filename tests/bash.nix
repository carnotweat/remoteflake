{
  name = "bash";
  machine = { lib, pkgs, ... }:
    let toDhall = lib.generators.toDhall { };
    in {
      genode.init.children.bash = let
        extraErisInputs' = with pkgs.genodePackages; {
          bash = lib.getEris "bin" pkgs.bash;
          cached_fs_rom = lib.getEris "bin" cached_fs_rom;
          vfs = lib.getEris "bin" vfs;
          vfs_pipe = lib.getEris "lib" vfs_pipe;
        };
        params = {
          bash = "${pkgs.bash}";
          coreutils = "${pkgs.coreutils}";
          cached_fs_rom = extraErisInputs'.cached_fs_rom.cap;
          vfs = extraErisInputs'.vfs.cap;
          vfs_pipe = extraErisInputs'.vfs_pipe.cap;
        };
      in {
        package = pkgs.genodePackages.init;
        extraErisInputs = builtins.attrValues extraErisInputs';
        configFile = pkgs.writeText "bash.child.dhall" ''
          ${./bash.dhall} ${toDhall params}
        '';
        extraInputs = with pkgs.genodePackages; [ pkgs.bash libc posix ];
      };
    };
  testScript = ''
    start_all()
    machine.wait_until_serial_output('child "bash" exited with exit value 0')
  '';
}
