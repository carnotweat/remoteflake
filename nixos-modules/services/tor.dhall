let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Init = Sigil.Init

let Libc = Sigil.Libc

let VFS = Sigil.VFS

in  λ(args : List Text) →
    λ(vfs : { lwip : Text, pipe : Text }) →
    λ(binary : Text) →
      Init.Child.flat
        Init.Child.Attributes::{
        , binary
        , config =
            Libc.toConfig
              Libc::{
              , args
              , pipe = Some "/dev/pipes"
              , rng = Some "/dev/entropy"
              , socket = Some "/dev/sockets"
              , vfs =
                [ VFS.dir
                    "dev"
                    [ VFS.leaf "null"
                    , VFS.leaf "log"
                    , VFS.leaf "rtc"
                    , VFS.leafAttrs
                        "terminal"
                        (toMap { name = "entropy", label = "entropy" })
                    , VFS.dir
                        "pipes"
                        [ VFS.leafAttrs "plugin" (toMap { load = vfs.pipe }) ]
                    , VFS.dir
                        "sockets"
                        [ VFS.leafAttrs
                            "plugin"
                            (toMap { load = vfs.lwip, label = "uplink" })
                        ]
                    ]
                , VFS.dir
                    "nix"
                    [ VFS.dir
                        "store"
                        [ VFS.fs
                            VFS.FS::{ label = "nix-store", writeable = "no" }
                        ]
                    ]
                ]
              }
        , resources = Init.Resources::{ caps = 512, ram = Sigil.units.MiB 384 }
        }
