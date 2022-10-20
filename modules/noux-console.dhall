-- SPDX-License-Identifier: CC0-1.0

let Genode = ./Genode.dhall

let Prelude = Genode.Prelude

let Init = Genode.Init

let Child = Init.Child

let Resources = Init.Resources

let ServiceRoute = Init.ServiceRoute

let nouxConsole =
      Init::{
      , children = toMap
          { nit_fb =
              Child.flat
                Child.Attributes::{
                , binary = "nit_fb"
                , config = Init.Config::{
                  , attributes = toMap { width = "300", height = "200" }
                  }
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
          , noux =
              Child.flat
                Child.Attributes::{
                , binary = "noux"
                , exitPropagate = True
                , resources = Genode.Init.Resources::{
                  , caps = 384
                  , ram = Genode.units.MiB 16
                  }
                , config = Genode.Init.Config::{
                  , attributes = toMap { verbose = "yes" }
                  , content =
                    [ Genode.Prelude.XML.text
                        ''
                        <fstab>
                        	<tar name="bash-minimal.tar" />
                        	<tar name="coreutils-minimal.tar" />
                        	<dir name="dev"> <log/> <null/> <zero/> </dir>
                        	<dir name="stage1"> <fs label="stage1"/> </dir>
                        	<dir name="stage2"> <fs label="stage2"/> </dir>
                        </fstab>
                        <start name="/bin/bash"/>
                        ''
                    ]
                  }
                , routes =
                  [ Genode.Init.ServiceRoute.parent "Timer"
                  , Genode.Init.ServiceRoute.parent "File_system"
                  , Genode.Init.ServiceRoute.child "Terminal" "terminal"
                  ]
                }
          }
      , verbose = True
      }

in  nouxConsole
