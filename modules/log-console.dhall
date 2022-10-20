-- SPDX-License-Identifier: CC0-1.0

let Genode = ./Genode.dhall

let Prelude = Genode.Prelude

let Init = Genode.Init

let Child = Init.Child

let Resources = Init.Resources

let ServiceRoute = Init.ServiceRoute

let logConsole =
      let routeLogRom =
              λ(label : Text)
            → ServiceRoute.parentLabel "ROM" (Some "log") (Some label)

      in  Init::{
          , children = toMap
              { nit_fb =
                  Child.flat
                    Child.Attributes::{
                    , binary = "nit_fb"
                    , provides = [ "Framebuffer", "Input" ]
                    , resources = Resources::{ ram = Genode.units.MiB 8 }
                    , routes = [ ServiceRoute.parent "Nitpicker" ]
                    }
              , terminal =
                  Child.flat
                    Child.Attributes::{
                    , binary = "terminal"
                    , provides = [ "Terminal" ]
                    , resources = Resources::{
                      , caps = 256
                      , ram = Genode.units.MiB 4
                      }
                    , routes =
                      [ ServiceRoute.parent "Timer"
                      , ServiceRoute.child "Framebuffer" "nit_fb"
                      , ServiceRoute.child "Input" "nit_fb"
                      ]
                    , config = Init.Config::{
                      , content =
                        [ Prelude.XML.text
                            ''
                            <vfs>
                            	<rom name="Inconsolata.ttf"/>
                            	<dir name="fonts">
                            		<dir name="monospace">
                            			<ttf name="regular" path="/Inconsolata.ttf" size_px="10"/>
                            		</dir>
                            	</dir>
                            </vfs>
                            ''
                        ]
                      }
                    }
              , terminal_log =
                  Child.flat
                    Child.Attributes::{
                    , binary = "terminal_log"
                    , provides = [ "LOG" ]
                    , routes = [ ServiceRoute.child "Terminal" "terminal" ]
                    }
              , log_core =
                  Child.flat
                    Child.Attributes::{
                    , binary = "log_core"
                    , routes =
                      [ routeLogRom "core_log"
                      , ServiceRoute.parent "Timer"
                      , ServiceRoute.childLabel
                          "LOG"
                          "terminal_log"
                          (Some "log")
                          (Some "core")
                      ]
                    }
              , log_kernel =
                  Child.flat
                    Child.Attributes::{
                    , binary = "log_core"
                    , routes =
                      [ routeLogRom "kernel_log"
                      , ServiceRoute.parent "Timer"
                      , ServiceRoute.childLabel
                          "LOG"
                          "terminal_log"
                          (Some "log")
                          (Some "kernel")
                      ]
                    }
              }
          }

in  logConsole
