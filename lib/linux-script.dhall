let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Prelude = Sigil.Prelude

let Args = { config : Sigil.Init.Type, rom : Sigil.BootModules.Type } : Type

let RomEntry = Prelude.Map.Entry Text Sigil.BootModules.ROM.Type

let addLine =
      λ(e : RomEntry) →
      λ(script : Text) →
        merge
          { RomText =
              λ(rom : Text) →
                ''
                ${script}
                echo ${Text/show rom} > ${Text/show e.mapKey}
                ''
          , RomPath =
              λ(rom : Text) →
                ''
                ${script}
                ln -s ${Text/show rom} ${Text/show e.mapKey}
                ''
          }
          e.mapValue

in  λ(args : Args) →
    λ(out : Text) →
      { config = Sigil.Init.render args.config
      , script =
          Prelude.List.fold
            RomEntry
            args.rom
            Text
            addLine
            ''
            #!/bin/sh
            ln -s ${out}/config config
            ''
      }
