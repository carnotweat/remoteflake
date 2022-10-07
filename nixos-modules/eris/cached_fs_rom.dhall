let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Init = Sigil.Init

let Child = Init.Child

in  λ(binary : Text) →
      Child.flat
        Child.Attributes::{
        , binary
        , priorityOffset = 2
        , resources = Sigil.Init.Resources::{
          , caps = 256
          , ram = Sigil.units.MiB 32
          }
        , config = Init.Config::{
          , policies =
            [ Init.Config.Policy::{
              , service = "ROM"
              , label =
                  Init.LabelSelector.Type.Partial
                    { prefix = Some "nixos -> ", suffix = None Text }
              }
            ]
          }
        }
