{ config, lib, pkgs, ... }:

{
  genode.core.children.eris_rom = {
    package = pkgs.genodePackages.cached_fs_rom;
    configFile = ./cached_fs_rom.dhall;
  };

  genode.core.children.eris_vfs = {
    fs = let
      vfsRump = lib.getEris' "lib" pkgs.genodePackages.rump "vfs_rump.lib.so";
    in {
      package = pkgs.genodePackages.vfs;
      extraErisInputs = [ vfsRump ];
      configFile = pkgs.writeText "rom-vfs.dhall" ''
        let Sigil = env:DHALL_SIGIL

        let VFS = Sigil.VFS

        in  ${./rom-vfs.dhall}
              "${config.block.partitions.store.guid}"
              Sigil.Init.Resources::{ caps = 256, ram = Sigil.units.MiB 32 }
              ( VFS.vfs
                  [ VFS.leafAttrs
                      "plugin"
                      (toMap { load = "${vfsRump.cap}", fs = "cd9660", ram = "12M", writeable="no" })
                  ]
              )
      '';
    };
    memory = {
      package = pkgs.genodePackages.vfs;
      configFile = pkgs.writeText "rom-vfs.dhall" ''
        let Sigil = env:DHALL_SIGIL

        let VFS = Sigil.VFS

        in  ${./rom-vfs.dhall}
              "${config.block.partitions.store.guid}"
              Sigil.Init.Resources::{ ram = Sigil.units.MiB 4 }
              ( VFS.vfs
                  [ VFS.leafAttrs
                      "tar"
                      ( toMap
                          { name =
                              "${config.system.build.tarball}/tarball/${config.system.build.tarball.fileName}.tar"
                          }
                      )
                  ]
              )
      '';
    };
  }.${config.genode.core.storeBackend};

}
