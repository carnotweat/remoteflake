let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Prelude = Sigil.Prelude

let Libc = Sigil.Libc

let VFS = Sigil.VFS

let Init = Sigil.Init

let Child = Init.Child

in  λ ( params
      : { bash : Text
        , coreutils : Text
        , cached_fs_rom : Text
        , vfs : Text
        , vfs_pipe : Text
        }
      ) →
    λ(binary : Text) →
      let init =
            Init::{
            , verbose = True
            , routes =
              [ Init.ServiceRoute.parent "Timer"
              , Init.ServiceRoute.parent "Rtc"
              ]
            , children = toMap
                { vfs =
                    Child.flat
                      Child.Attributes::{
                      , binary = params.vfs
                      , provides = [ "File_system" ]
                      , resources = Sigil.Init.Resources::{
                        , caps = 256
                        , ram = Sigil.units.MiB 8
                        }
                      , routes =
                            [ Init.ServiceRoute.parent "ROM" ]
                          # Prelude.List.map
                              Text
                              Init.ServiceRoute.Type
                              Init.ServiceRoute.parent
                              [ "File_system", "Rtc" ]
                      , config = Init.Config::{
                        , content =
                          [ VFS.vfs
                              [ VFS.dir
                                  "dev"
                                  [ VFS.dir
                                      "pipes"
                                      [ VFS.leafAttrs
                                          "plugin"
                                          (toMap { load = params.vfs_pipe })
                                      ]
                                  , VFS.leaf "log"
                                  , VFS.leaf "null"
                                  , VFS.leaf "rtc"
                                  , VFS.leaf "zero"
                                  ]
                              , VFS.dir
                                  "usr"
                                  [ VFS.dir
                                      "bin"
                                      [ VFS.symlink
                                          "env"
                                          "${params.coreutils}/bin/env"
                                      ]
                                  ]
                              , VFS.dir "ram" [ VFS.leaf "ram" ]
                              , VFS.dir
                                  "nix"
                                  [ VFS.dir
                                      "store"
                                      [ VFS.fs VFS.FS::{ label = "nix-store" } ]
                                  ]
                              , VFS.inline
                                  "script.sh"
                                  ''
                                  bash --version
                                  bash -c "bash --version"
                                  ''
                              ]
                          ]
                        , policies =
                          [ Init.Config.Policy::{
                            , service = "File_system"
                            , label = Init.LabelSelector.prefix "shell"
                            , attributes = toMap
                                { root = "/", writeable = "yes" }
                            , diag = Some True
                            }
                          , Init.Config.Policy::{
                            , service = "File_system"
                            , label = Init.LabelSelector.prefix "vfs_rom"
                            , attributes = toMap { root = "/" }
                            , diag = Some True
                            }
                          ]
                        }
                      }
                , vfs_rom =
                    Child.flat
                      Child.Attributes::{
                      , binary = params.cached_fs_rom
                      , provides = [ "ROM" ]
                      , resources = Init.Resources::{
                        , caps = 256
                        , ram = Sigil.units.MiB 32
                        }
                      , config = Init.Config::{
                        , policies =
                          [ Init.Config.Policy::{
                            , service = "ROM"
                            , label = Init.LabelSelector.prefix "shell"
                            , diag = Some True
                            }
                          , Init.Config.Policy::{
                            , service = "ROM"
                            , label = Init.LabelSelector.prefix "/nix/store/"
                            , diag = Some True
                            }
                          ]
                        }
                      }
                , shell =
                    Child.flat
                      Child.Attributes::{
                      , binary = "${params.bash}/bin/bash"
                      , exitPropagate = True
                      , resources = Sigil.Init.Resources::{
                        , caps = 256
                        , ram = Sigil.units.MiB 8
                        }
                      , config =
                          ( Libc.toConfig
                              Libc::{
                              , pipe = Some "/dev/pipe"
                              , rtc = Some "/dev/rtc"
                              , vfs = [ VFS.fs VFS.FS::{ label = "root" } ]
                              , env = toMap
                                  { TERM = "screen"
                                  , PATH =
                                      "${params.coreutils}/bin:${params.bash}/bin"
                                  }
                              , args = [ "bash", "/script.sh" ]
                              }
                          )
                        with attributes = toMap { ld_verbose = "true" }
                      , routes =
                        [ { service =
                            { name = "ROM"
                            , label = Init.LabelSelector.prefix "urn:erisx2:"
                            }
                          , route = Init.Route.parent (None Text)
                          }
                        ]
                      }
                }
            }

      in  Init.toChild init Init.Attributes::{=}
