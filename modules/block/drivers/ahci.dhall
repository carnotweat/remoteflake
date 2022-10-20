let Genode = ../../Genode.dhall

let Init = Genode.Init

let ServiceRoute = Init.ServiceRoute

let Child = Init.Child

in    λ(cfg : {})
    → Child.flat
        Child.Attributes::{
        , binary = "ahci_drv"
        , config = Init.Config::{
          , content =
            [ Genode.Prelude.XML.leaf
                { name = "default-policy"
                , attributes = toMap { device = "0", writeable = "yes" }
                }
            ]
          }
        , provides = [ "Block" ]
        , resources = Init.Resources::{ caps = 256, ram = Genode.units.MiB 10 }
        , routes =
          [ ServiceRoute.parent "Timer"
          , ServiceRoute.parentLabel "Platform" (None Text) (Some "ahci_drv")
          ]
        }
