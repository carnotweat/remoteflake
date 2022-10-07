let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Init = Sigil.Init

let Child = Init.Child

in  λ(gptGuid : Text) →
    λ(resources : Init.Resources.Type) →
    λ(vfsConfig : Sigil.Prelude.XML.Type) →
    λ(binary : Text) →
      Child.flat
        Child.Attributes::{
        , binary
        , priorityOffset = 2
        , resources
        , config = Init.Config::{
          , content = [ vfsConfig ]
          , policies =
            [ Init.Config.Policy::{
              , service = "File_system"
              , label = Init.LabelSelector.prefix "eris_rom"
              , attributes = toMap { root = "/" }
              }
            , Init.Config.Policy::{
              , service = "File_system"
              , label = Init.LabelSelector.suffix "nix-store"
              , attributes = toMap { root = "/nix/store" }
              }
            ]
          }
        , routes =
          [ { service = Init.Service::{ name = "Block" }
            , route = Init.Route.child "drivers" (Some gptGuid)
            }
          ]
        }
