let Genode = ../../Genode.dhall

let Prelude = Genode.Prelude

let Init = Genode.Init

let ServiceRoute = Init.ServiceRoute

let Child = Init.Child

let XML = Prelude.XML

let toChildren =
        λ(cfg : {})
      → toMap
          { file_system =
              Child.flat
                Child.Attributes::{
                , binary = "vfs"
                , config = Init.Config::{
                  , content =
                    [ XML.element
                        { name = "vfs"
                        , attributes = XML.emptyAttributes
                        , content =
                          [ XML.leaf
                              { name = "rump"
                              , attributes = toMap
                                  { fs = "ext2fs"
                                  , writeable = "yes"
                                  , ram = "8M"
                                  }
                              }
                          ]
                        }
                    , XML.leaf
                        { name = "default-policy"
                        , attributes = toMap { root = "/" }
                        }
                    ]
                  }
                , provides = [ "File_system" ]
                , resources = Init.Resources::{
                  , caps = 256
                  , ram = Genode.units.MiB 12
                  }
                , routes =
                  [ ServiceRoute.parent "Timer"
                  , ServiceRoute.child "Block" "block_router"
                  ]
                }
          , rom =
              Child.flat
                Child.Attributes::{
                , binary = "fs_rom"
                , provides = [ "ROM" ]
                , resources = Init.Resources::{
                  , caps = 256
                  , ram = Genode.units.MiB 64
                  }
                , routes = [ ServiceRoute.child "File_system" "file_system" ]
                }
          }

in  toChildren
