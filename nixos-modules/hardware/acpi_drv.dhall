let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Init = Sigil.Init

in  λ(binary : Text) →
      Init.Child.flat
        Init.Child.Attributes::{
        , binary
        , priorityOffset = 1
        , resources = Init.Resources::{
          , caps = 400
          , ram = Sigil.units.MiB 4
          , constrainPhys = True
          }
        , routes =
          [ Init.ServiceRoute.parent "IRQ"
          , Init.ServiceRoute.parent "IO_MEM"
          , Init.ServiceRoute.parent "IO_PORT"
          ]
        , produceReports =
            let f = λ(x : Text) → { report = x, rom = x }

            in  [ f "acpi", f "smbios_table" ]
        }
