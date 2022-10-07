let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Prelude = Sigil.Prelude

let Init = Sigil.Init

in  { Genode
    , Type =
        { children : Prelude.Map.Type Text Init.Child.Type
        , rom : Sigil.BootModules.Type
        }
    , default.rom = [] : Sigil.BootModules.Type
    , initToChildren =
        λ(init : Init.Type) →
          toMap
            { init =
                Init.toChild
                  init
                  Init.Attributes::{
                  , routes =
                    [ Init.ServiceRoute.parentLabel
                        "LOG"
                        (Some "SOTEST")
                        (Some "unlabeled")
                    , Init.ServiceRoute.parent "IO_MEM"
                    , Init.ServiceRoute.parent "IO_PORT"
                    , Init.ServiceRoute.parent "IRQ"
                    , Init.ServiceRoute.parent "VM"
                    ]
                  }
            }
    }
