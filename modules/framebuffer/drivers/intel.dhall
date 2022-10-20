let Genode = ../../Genode.dhall

let Prelude = Genode.Prelude

let XML = Prelude.XML

let Init = Genode.Init

let ServiceRoute = Init.ServiceRoute

let Child = Init.Child

let Mode = ../Mode

let Entry = Prelude.Map.Entry Text Mode.Type

let modesToXML =
        λ(modes : Mode.Map)
      → let render =
                λ(entry : Entry)
              → XML.leaf
                  { name = "connector"
                  , attributes =
                      let mode = entry.mapValue

                      in  toMap
                            { name = entry.mapKey
                            , width = Prelude.Natural.show mode.width
                            , height = Prelude.Natural.show mode.height
                            , hz = Prelude.Natural.show mode.refresh
                            , brightness = Prelude.Natural.show mode.brightness
                            , enabled = "true"
                            }
                  }

        in  Prelude.List.map Entry XML.Type render modes

in    λ(cfg : { modes : Mode.Map })
    → Child.flat
        Child.Attributes::{
        , binary = "intel_fb_drv"
        , config = Init.Config::{ content = modesToXML cfg.modes }
        , provides = [ "Framebuffer" ]
        , resources = Init.Resources::{ caps = 1000, ram = Genode.units.MiB 64 }
        , routes =
          [ ServiceRoute.childLabel
              "Platform"
              "platform_drv"
              (None Text)
              (Some "intel_fb_drv")
          , ServiceRoute.parent "Report"
          , ServiceRoute.parent "Timer"
          , ServiceRoute.parent "IO_PORT"
          , ServiceRoute.parent "IO_MEM"
          ]
        }
