let Genode = ../../Genode.dhall

let Prelude = Genode.Prelude

let Init = Genode.Init

let ServiceRoute = Init.ServiceRoute

let Child = Init.Child

let Mode = ../Mode

let toYesNo = λ(_ : Bool) → if _ then "yes" else "no"

in    λ(cfg : { buffered : Bool, depth : Natural, mode : Optional Mode.Type })
    → Child.flat
        Child.Attributes::{
        , binary = "vesa_fb_drv"
        , config = Init.Config::{
          , attributes =
                toMap
                  { buffered = toYesNo cfg.buffered
                  , depth = Prelude.Natural.show cfg.depth
                  }
              # Prelude.List.concat
                  (Prelude.Map.Entry Text Text)
                  ( Prelude.List.map
                      Mode.Type
                      (Prelude.Map.Type Text Text)
                      (   λ(mode : Mode.Type)
                        → toMap
                            { width = Prelude.Natural.show mode.width
                            , height = Prelude.Natural.show mode.height
                            }
                      )
                      (Prelude.Optional.toList Mode.Type cfg.mode)
                  )
          }
        , provides = [ "Framebuffer" ]
        , resources = Init.Resources::{ caps = 256, ram = Genode.units.MiB 16 }
        , routes =
          [ ServiceRoute.parent "Timer"
          , ServiceRoute.parent "IO_MEM"
          , ServiceRoute.parent "IO_PORT"
          , ServiceRoute.parentLabel "Platform" (None Text) (Some "vesa_fb_drv")
          ]
        }
