let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Prelude = Sigil.Prelude

let BootModules = Sigil.BootModules

let RomEntry = Prelude.Map.Entry Text BootModules.ROM.Type

let compile =
      λ(addressType : Text) →
      λ(boot : Sigil.Boot.Type) →
      λ(out : Text) →
        let NaturalIndex = { index : Natural, value : Text }

        let TextIndex = { index : Text, value : Text }

        let moduleKeys =
              Prelude.Map.keys Text BootModules.ROM.Type boot.rom # [ "config" ]

        let moduleValues =
              let f =
                    λ(e : RomEntry) →
                      merge
                        { RomText = λ(text : Text) → ".ascii ${Text/show text}"
                        , RomPath = λ(path : Text) → ".incbin ${Text/show path}"
                        }
                        e.mapValue

              in    Prelude.List.map RomEntry Text f boot.rom
                  # [ ".incbin \"${out}/config\"" ]

        let map =
              λ(list : List Text) →
              λ(f : TextIndex → Text) →
                let indexedNatural = Prelude.List.indexed Text list

                let indexed =
                      Prelude.List.map
                        NaturalIndex
                        TextIndex
                        ( λ(x : NaturalIndex) →
                            { index = Prelude.Natural.show x.index
                            , value = x.value
                            }
                        )
                        indexedNatural

                let texts = Prelude.List.map TextIndex Text f indexed

                in  Prelude.Text.concatSep "\n" texts

        let mapNames = map moduleKeys

        let mapValues = map moduleValues

        let asm =
                  ''
                  .set MIN_PAGE_SIZE_LOG2, 12
                  .set DATA_ACCESS_ALIGNM_LOG2, 3

                  .section .data

                  .p2align DATA_ACCESS_ALIGNM_LOG2
                  .global _boot_modules_headers_begin
                  _boot_modules_headers_begin:

                  ''
              ++  mapNames
                    ( λ(m : TextIndex) →
                        ''
                        ${addressType} _boot_module_${m.index}_name
                        ${addressType} _boot_module_${m.index}_begin
                        ${addressType} _boot_module_${m.index}_end - _boot_module_${m.index}_begin
                        ''
                    )
              ++  ''
                  .global _boot_modules_headers_end
                  _boot_modules_headers_end:

                  ''
              ++  mapNames
                    ( λ(m : TextIndex) →
                        ''
                        .p2align DATA_ACCESS_ALIGNM_LOG2
                        _boot_module_${m.index}_name:
                        .string "${m.value}"
                        .byte 0

                        ''
                    )
              ++  ''
                  .section .data.boot_modules_binaries

                  .global _boot_modules_binaries_begin
                  _boot_modules_binaries_begin:

                  ''
              ++  mapValues
                    ( λ(m : TextIndex) →
                        ''
                        .p2align MIN_PAGE_SIZE_LOG2
                        _boot_module_${m.index}_begin:
                        ${m.value}
                        _boot_module_${m.index}_end:
                        ''
                    )
              ++  ''
                  .p2align MIN_PAGE_SIZE_LOG2
                  .global _boot_modules_binaries_end
                  _boot_modules_binaries_end:
                  ''

        in  { config = Sigil.Init.render boot.config
            , modules_asm = asm
            , stats =
                let sum = Sigil.Init.resources boot.config

                in  "RAM=${Prelude.Natural.show sum.ram}"
            }

let funcs = { to32bitImage = compile ".long", to64bitImage = compile ".quad" }

in  funcs.to64bitImage
