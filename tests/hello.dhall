let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Init = Sigil.Init

let Child = Init.Child

let Libc = Sigil.Libc

in  λ(binary : Text) →
      Child.flat
        Child.Attributes::{
        , binary
        , exitPropagate = True
        , resources = Sigil.Init.Resources::{
          , caps = 500
          , ram = Sigil.units.MiB 10
          }
        , config = Libc.toConfig Libc::{ args = [ "hello" ] }
        }
