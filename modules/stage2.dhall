let Genode = ./Genode.dhall

let Init = Genode.Init

let Child = Init.Child

let ServiceRoute = Init.ServiceRoute

let romRoutes =
      [ { service =
            { name = "ROM", label = Init.LabelSelector.Type.Last "ld.lib.so" }
        , route = Init.Route.parent
        }
      , { service =
            { name = "ROM", label = Init.LabelSelector.Type.Last "init" }
        , route = Init.Route.parent
        }
      , ServiceRoute.child "ROM" "cached_fs_rom"
      ]

let stage2init =
      Init::{
      , children = toMap
          { cached_fs_rom =
              Child.flat
                Child.Attributes::{
                , binary = "cached_fs_rom"
                , provides = [ "ROM" ]
                , resources = Genode.Init.Resources::{
                  , caps = 1024
                  , ram = Genode.units.MiB 32
                  }
                , routes = [ Genode.Init.ServiceRoute.parent "File_system" ]
                }
          , noux_console =
              Init.toChild
                ./noux-console.dhall
                Init.Attributes::{
                , routes =
                      romRoutes
                    # [ Genode.Init.ServiceRoute.parent "File_system"
                      , Genode.Init.ServiceRoute.parent "Nitpicker"
                      , Genode.Init.ServiceRoute.parent "Rtc"
                      , Genode.Init.ServiceRoute.parent "Timer"
                      ]
                }
          }
      , verbose = True
      }

in  { init = stage2init, files.stage2config = Init.render stage2init }
