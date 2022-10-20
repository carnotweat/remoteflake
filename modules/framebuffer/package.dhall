let Genode = ../Genode.dhall

let Prelude = Genode.Prelude

let Mode = ./Mode

let Configuration
    : Type
    = < Boot : {}
      | Intel : { modes : Mode.Map }
      | Vesa : { buffered : Bool, depth : Natural, mode : Optional Mode.Type }
      >

let ModesAvailable = Prelude.Map.Type Text (List Mode.Type)

let Modes = Prelude.Map.Type Text Mode.Type

in  { Mode = Mode
    , Modes = Modes
    , ModesAvailable = ModesAvailable
    , Type = Configuration
    , toChild =
          λ(cfg : Configuration)
        → merge
            { Boot = ./drivers/boot.dhall
            , Intel = ./drivers/intel.dhall
            , Vesa = ./drivers/vesa.dhall
            }
            cfg
    }
