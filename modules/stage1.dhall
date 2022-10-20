-- SPDX-License-Identifier: CC0-1.0

let Genode = ./Genode.dhall

let Prelude = Genode.Prelude

let XML = Prelude.XML

let Init = Genode.Init

let Child = Init.Child

let Resources = Init.Resources

let ServiceRoute = Init.ServiceRoute

let Block = ./block/package.dhall

let Framebuffer = ./framebuffer/package.dhall

let Storage = ./storage/package.dhall

let Configuration = ./Configuration.dhall

let parentLabelLast =
        λ(service : Text)
      → λ(label : Text)
      → { service =
            { name = service, label = Init.LabelSelector.Type.Last label }
        , route = Init.Route.parent
        }

let stage1
    : Configuration → Init.Type
    =   λ(cfg : Configuration)
      → Init::{
        , children =
              toMap
                { framebuffer = Framebuffer.toChild cfg.framebuffer
                , input_filter =
                    Child.flat
                      Child.Attributes::{
                      , binary = "input_filter"
                      , provides = [ "Input" ]
                      , routes =
                        [ ServiceRoute.parentLabel
                            "ROM"
                            (Some "config")
                            (Some "config -> input_filter.config")
                        , ServiceRoute.childLabel
                            "Input"
                            "ps2_drv"
                            (Some "ps2")
                            (None Text)
                        ]
                      }
                , ps2_drv =
                    Child.flat
                      Child.Attributes::{
                      , binary = "ps2_drv"
                      , provides = [ "Input" ]
                      , routes =
                        [ ServiceRoute.parentLabel
                            "Platform"
                            (None Text)
                            (Some "ps2_drv")
                        , ServiceRoute.parent "Timer"
                        ]
                      }
                , nitpicker =
                    Child.flat
                      Child.Attributes::{
                      , binary = "nitpicker"
                      , config = Init.Config::{
                        , content =
                          [ XML.text
                              ''
                              <domain name="pointer" layer="1" content="client" label="no" origin="pointer" />
                              <domain name="default" layer="2" content="client" label="yes" hover="always" focus="click"/>
                              <policy label_prefix="pointer" domain="pointer"/>
                              <default-policy domain="default"/>
                               ''
                          ]
                        }
                      , provides = [ "Nitpicker" ]
                      , routes =
                        [ ServiceRoute.parent "Timer"
                        , ServiceRoute.child "Framebuffer" "framebuffer"
                        , ServiceRoute.child "Input" "input_filter"
                        ]
                      }
                , pointer =
                    Child.flat
                      Child.Attributes::{
                      , binary = "pointer"
                      , routes = [ ServiceRoute.child "Nitpicker" "nitpicker" ]
                      }
                , log_console =
                    Init.toChild
                      ./log-console.dhall
                      Init.Attributes::{
                      , routes =
                        [ ServiceRoute.child "Nitpicker" "nitpicker"
                        , ServiceRoute.parent "Rtc"
                        , ServiceRoute.parent "Timer"
                        ]
                      }
                , block = Block.toChild cfg.block
                , block_partitions =
                    Child.flat
                      Child.Attributes::{
                      , binary = "part_block"
                      , config = Init.Config::{
                        , content =
                              Prelude.List.map
                                Natural
                                XML.Type
                                (   λ(i : Natural)
                                  → XML.leaf
                                      { name = "policy"
                                      , attributes =
                                          let partition =
                                                Prelude.Natural.show (i + 1)

                                          in  toMap
                                                { label_suffix = " ${partition}"
                                                , partition = partition
                                                , writeable = "yes"
                                                }
                                      }
                                )
                                (Prelude.Natural.enumerate 128)
                            # [ XML.leaf
                                  { name = "report"
                                  , attributes = toMap { partitions = "yes" }
                                  }
                              ]
                        }
                      , resources = Resources::{
                        , caps = 256
                        , ram = Genode.units.MiB 8
                        }
                      , provides = [ "Block" ]
                      , routes =
                        [ ServiceRoute.child "Block" "block"
                        , ServiceRoute.child "Report" "block_router"
                        ]
                      }
                , block_router =
                    Child.flat
                      Child.Attributes::{
                      , binary = "block_router"
                      , config = Init.Config::{
                        , attributes = toMap { verbose = "yes" }
                        , content =
                          [ XML.element
                              { name = "default-policy"
                              , attributes = XML.emptyAttributes
                              , content =
                                [ XML.leaf
                                    { name = "partition"
                                    , attributes = toMap
                                        { type = ./partition-type
                                        , writeable = "yes"
                                        }
                                    }
                                ]
                              }
                          ]
                        }
                      , resources = Resources::{
                        , caps = 256
                        , ram = Genode.units.MiB 8
                        }
                      , provides = [ "Block", "Report" ]
                      , routes =
                        [ ServiceRoute.parent "Timer"
                        , ServiceRoute.child "Block" "block_partitions"
                        ]
                      }
                , stage2 =
                    Init.toChild
                      Init::{=}
                      Init.Attributes::{
                      , resources = Resources::{
                        , caps = 8192
                        , ram = Genode.units.MiB 64
                        }
                      , routes =
                        [ { service =
                              { name = "ROM"
                              , label = Init.LabelSelector.Type.Last "ld.lib.so"
                              }
                          , route = Init.Route.parent
                          }
                        , { service =
                              { name = "ROM"
                              , label = Init.LabelSelector.Type.Last "init"
                              }
                          , route = Init.Route.parent
                          }
                        , ServiceRoute.childLabel
                            "ROM"
                            "rom"
                            (Some "config")
                            (Some "stage2config")
                        , ServiceRoute.child "ROM" "rom"
                        , ServiceRoute.parent "Rtc"
                        , ServiceRoute.parent "Timer"
                        , ServiceRoute.parent "IO_MEM"
                        , ServiceRoute.parent "IO_PORT"
                        , ServiceRoute.parent "Platform"
                        , ServiceRoute.parent "VM"
                        , ServiceRoute.child "Nitpicker" "nitpicker"
                        , parentLabelLast "File_system" "stage1"
                        , ServiceRoute.child "File_system" "file_system"
                        ]
                      , suppressConfig = True
                      }
                }
            # Storage.toChildren cfg.storage
        , verbose = True
        }

in  stage1
