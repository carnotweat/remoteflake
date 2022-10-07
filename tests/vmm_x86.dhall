let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Init = Sigil.Init

let Child = Init.Child

in  λ(binary : Text) →
      Child.flat
        Child.Attributes::{
        , binary
        , exitPropagate = True
        , resources = Init.Resources::{ caps = 2048, ram = Sigil.units.MiB 256 }
        , routes = [ Sigil.Init.ServiceRoute.parent "VM" ]
        }
