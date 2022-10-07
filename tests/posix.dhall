let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Prelude = Sigil.Prelude

let Init = Sigil.Init

let Child = Init.Child

let Libc = Sigil.Libc

let VFS = Sigil.VFS

in  λ(params : { bash : Text, coreutils : Text, script : Text }) →
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
                      , binary = "vfs"
                      , config = Init.Config::{
                        , content =
                          [ Prelude.XML.text
                              ''
                              <vfs>
                              <dir name="dev"> <log name="stdout" label="stdout"/> <log name="stderr" label="stderr"/> <null/> <pipe/> <rtc/> <zero/> </dir>
                              <dir name="usr"><dir name="bin"><symlink name="env" target="${params.coreutils}/bin/env"/></dir></dir>
                              <dir name="tmp"><ram/></dir>
                              <dir name="nix"><fs label="nix" root="nix"/></dir>
                              </vfs>
                              ''
                          ]
                        , policies =
                          [ Init.Config.Policy::{
                            , service = "File_system"
                            , label =
                                Init.LabelSelector.Type.Partial
                                  { prefix = Some "shell", suffix = None Text }
                            , attributes = toMap
                                { root = "/", writeable = "yes" }
                            }
                          ]
                        }
                      , provides = [ "File_system" ]
                      , resources = Sigil.Init.Resources::{
                        , caps = 256
                        , ram = Sigil.units.MiB 8
                        }
                      , routes =
                          Prelude.List.map
                            Text
                            Init.ServiceRoute.Type
                            Init.ServiceRoute.parent
                            [ "File_system", "Rtc" ]
                      }
                , store_rom =
                    Child.flat
                      Child.Attributes::{
                      , binary = "cached_fs_rom"
                      , provides = [ "ROM" ]
                      , resources = Init.Resources::{
                        , caps = 256
                        , ram = Sigil.units.MiB 4
                        }
                      , routes =
                        [ Init.ServiceRoute.parentLabel
                            "File_system"
                            (None Text)
                            (Some "nix")
                        ]
                      }
                , shell =
                    Child.flat
                      Child.Attributes::{
                      , binary = "bash"
                      , config =
                          Libc.toConfig
                            Libc::{
                            , pipe = Some "/dev/pipe"
                            , rtc = Some "/dev/rtc"
                            , vfs = [ VFS.leaf "fs" ]
                            , args = [ "bash", params.script ]
                            }
                      , exitPropagate = True
                      , resources = Sigil.Init.Resources::{
                        , caps = 256
                        , ram = Sigil.units.MiB 8
                        }
                      , routes =
                        [ { service =
                            { name = "ROM"
                            , label =
                                Init.LabelSelector.Type.Partial
                                  { prefix = Some "/nix/store/"
                                  , suffix = None Text
                                  }
                            }
                          , route =
                              Init.Route.Type.Child
                                { name = "store_rom"
                                , label = None Text
                                , diag = None Bool
                                }
                          }
                        ]
                      }
                }
            }

      in  Test::{ children = Test.initToChildren init }
