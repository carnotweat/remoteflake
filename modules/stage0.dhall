-- SPDX-License-Identifier: CC0-1.0

let Genode = ./Genode.dhall

let Prelude = Genode.Prelude

let XML = Prelude.XML

let Configuration = ./Configuration.dhall

let Init = Genode.Init

let Child = Init.Child

let Resources = Init.Resources

let ServiceRoute = Init.ServiceRoute

let label =
        λ(label : Text)
      → { local = label, route = label } : Child.Attributes.Label

let inlineConfig =
        λ(name : Text)
      → λ(config : Init.Config.Type)
      → XML.element
          { name = "inline"
          , attributes = toMap { name = name }
          , content =
              Prelude.Optional.toList XML.Type (Init.Config.toXML config)
          }

let stage0 =
        λ(cfg : Configuration)
      → λ(stage1 : Init.Type)
      → let timerRoute = ServiceRoute.child "Timer" "timer"

        in  Init::{
            , children = toMap
                { config_vfs =
                    Child.flat
                      Child.Attributes::{
                      , binary = "vfs"
                      , config = Init.Config::{
                        , content =
                          [ XML.element
                              { name = "vfs"
                              , attributes = XML.emptyAttributes
                              , content =
                                [ XML.leaf
                                    { name = "ram"
                                    , attributes = XML.emptyAttributes
                                    }
                                , XML.element
                                    { name = "import"
                                    , attributes = XML.emptyAttributes
                                    , content =
                                      [ inlineConfig
                                          "stage1config"
                                          (Init.config stage1)
                                      , inlineConfig
                                          "input_filter.config"
                                          cfg.input.filterConfig
                                      ]
                                    }
                                ]
                              }
                          , XML.leaf
                              { name = "default-policy"
                              , attributes = toMap
                                  { root = "/", writeable = "yes" }
                              }
                          ]
                        }
                      , provides = [ "File_system" ]
                      , resources = Init.Resources::{
                        , caps = 256
                        , ram = Genode.units.MiB 4
                        }
                      }
                , config_rom =
                    Child.flat
                      Child.Attributes::{
                      , binary = "fs_rom"
                      , provides = [ "ROM" ]
                      , resources = Init.Resources::{
                        , caps = 256
                        , ram = Genode.units.MiB 2
                        }
                      , routes =
                        [ ServiceRoute.child "File_system" "config_vfs" ]
                      }
                , timer =
                    Child.flat
                      Child.Attributes::{
                      , binary = "timer_drv"
                      , provides = [ "Timer" ]
                      }
                , rtc =
                    Child.flat
                      Child.Attributes::{
                      , binary = "rtc_drv"
                      , provides = [ "Rtc" ]
                      , routes =
                        [ ServiceRoute.parent "IO_PORT"
                        , ServiceRoute.parent "IO_MEM"
                        ]
                      }
                , acpi_drv =
                    Child.flat
                      Child.Attributes::{
                      , binary = "acpi_drv"
                      , priority = 1
                      , resources = Resources::{
                        , caps = 350
                        , ram = Genode.units.MiB 4
                        }
                      , romReports = [ label "acpi", label "smbios_table" ]
                      , routes = [ ServiceRoute.parent "IO_MEM" ]
                      }
                , platform_drv =
                    Child.flat
                      Child.Attributes::{
                      , binary = "platform_drv"
                      , resources = Resources::{
                        , caps = 400
                        , ram = Genode.units.MiB 4
                        , constrainPhys = True
                        }
                      , reportRoms = [ label "acpi" ]
                      , romReports = [ label "pci" ]
                      , provides = [ "Acpi", "Platform" ]
                      , routes =
                        [ ServiceRoute.parent "IRQ"
                        , ServiceRoute.parent "IO_MEM"
                        , ServiceRoute.parent "IO_PORT"
                        , timerRoute
                        , ServiceRoute.parentLabel
                            "ROM"
                            (Some "system")
                            (Some "system")
                        ]
                      , config = Init.Config::{
                        , attributes = toMap { system = "yes" }
                        , content =
                          [ XML.text
                              ''
                                <report pci="yes"/>
                                <policy label_suffix="ps2_drv">
                                  <device name="PS2"/>
                                </policy>
                                <policy label_suffix="vesa_fb_drv">
                                  <pci class="VGA"/>
                                </policy>
                                <policy label_suffix="ahci_drv">
                                  <pci class="AHCI"/>
                                </policy>
                                <policy label_suffix="nvme_drv">
                                  <pci class="NVME"/>
                                </policy>
                                <policy label_suffix="usb_drv">
                                  <pci class="USB"/>
                                </policy>
                                <policy label_suffix="intel_fb_drv">
                                  <pci class="VGA"/>
                                  <pci bus="0" device="0" function="0"/>
                                  <pci class="ISABRIDGE"/>
                                </policy>
                                <policy label_suffix="-&gt; wifi">
                                  <pci class="WIFI"/>
                                </policy>
                                <policy label_suffix="-&gt; nic">
                                  <pci class="ETHERNET"/>
                                </policy>
                                <policy label_suffix="-&gt; audio">
                                  <pci class="AUDIO"/>
                                  <pci class="HDAUDIO"/>
                                </policy>
                                <policy label="acpica"/>
                              ''
                          ]
                        }
                      }
                , stage1 =
                    Init.toChild
                      stage1
                      Init.Attributes::{
                      , resources = Resources::{
                        , caps = 8192
                        , ram = Genode.units.MiB 64
                        }
                      , routes =
                          let parentRom =
                                  λ(label : Text)
                                → ServiceRoute.parentLabel
                                    "ROM"
                                    (Some label)
                                    (None Text)

                          in  [ timerRoute
                              , parentRom "core_log"
                              , parentRom "kernel_log"
                              , parentRom "platform_info"
                              , parentRom "ld.lib.so"
                              , ServiceRoute.parent "IO_MEM"
                              , ServiceRoute.parent "IO_PORT"
                              , ServiceRoute.child "Platform" "platform_drv"
                              , ServiceRoute.childLabel
                                  "ROM"
                                  "config_rom"
                                  (Some "config")
                                  (Some "stage1config")
                              , ServiceRoute.child "Platform" "platform_drv"
                              , ServiceRoute.childLabel
                                  "ROM"
                                  "config_rom"
                                  (Some "config -> input_filter.config")
                                  (None Text)
                              , ServiceRoute.child "File_system" "config_vfs"
                              ]
                      , suppressConfig = True
                      }
                }
            }

in    λ(cfg : Configuration)
    → λ(stage1 : Init.Type)
    → let init = stage0 cfg stage1 in { init = init, config = Init.render init }
