let Genode = env:DHALL_GENODE

let Prelude = Genode.Prelude

let BootModules = Genode.BootModules

let RomEntry = Prelude.Map.Entry Text BootModules.ROM.Type

let copy =
        λ(out : Text)
      → λ(entry : RomEntry)
      → merge
          { RomPath =
                λ(path : Text)
              → ''
                cp '${path}' '${out}/${entry.mapKey}'
                ''
          , RomText =
                λ(text : Text)
              → ''
                cat > ${out}/${entry.mapKey} << EOR
                ${text}
                EOR
                ''
          }
          entry.mapValue

let copyScript
    : Text → BootModules.Type → Text
    = λ(out : Text) → Prelude.Text.concatMap RomEntry (copy out)

in  copyScript
