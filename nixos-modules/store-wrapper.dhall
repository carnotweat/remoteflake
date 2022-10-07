let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Prelude = Sigil.Prelude

let Init = Sigil.Init

let Child = Init.Child

let TextMapType = Prelude.Map.Type Text

let ChildMapType = TextMapType Child.Type

let Manifest/Type = TextMapType (TextMapType Text)

in  λ ( params
      : { binaries : { rtc_drv : Text }
        , extraCoreChildren : ChildMapType
        , subinit : Init.Type
        , storeSize : Natural
        , routes : List Init.ServiceRoute.Type
        , bootManifest : Manifest/Type
        }
      ) →
      Sigil.Boot::{
      , config = Init::{
        , routes = params.routes
        , children =
            let child = Prelude.Map.keyValue Child.Type

            in    [ child
                      "timer"
                      ( Child.flat
                          Child.Attributes::{
                          , binary = "timer_drv"
                          , config = Init.Config::{
                            , policies =
                              [ Init.Config.Policy::{
                                , service = "Timer"
                                , label = Init.LabelSelector.none
                                }
                              ]
                            }
                          }
                      )
                  , child
                      "rtc"
                      ( Child.flat
                          Child.Attributes::{
                          , binary = params.binaries.rtc_drv
                          , routes = [ Init.ServiceRoute.parent "IO_PORT" ]
                          , config = Init.Config::{
                            , policies =
                              [ Init.Config.Policy::{
                                , service = "Rtc"
                                , label = Init.LabelSelector.none
                                }
                              ]
                            }
                          }
                      )
                  ]
                # params.extraCoreChildren
                # [ child
                      "nixos"
                      ( Init.toChild
                          params.subinit
                          Init.Attributes::{
                          , exitPropagate = True
                          , priorityOffset = 3
                          , resources = Init.Resources::{
                            , ram = Sigil.units.MiB 4
                            }
                          , routes =
                              let parentROMs =
                                    Prelude.List.concatMap
                                      Text
                                      Init.ServiceRoute.Type
                                      ( λ(suffix : Text) →
                                          Prelude.List.map
                                            Text
                                            Init.ServiceRoute.Type
                                            ( λ(prefix : Text) →
                                                { service =
                                                  { name = "ROM"
                                                  , label =
                                                      Init.LabelSelector.Type.Partial
                                                        { prefix = Some prefix
                                                        , suffix = Some suffix
                                                        }
                                                  }
                                                , route =
                                                    Init.Route.parent
                                                      (Some suffix)
                                                }
                                            )
                                            ( Prelude.Map.keys
                                                Text
                                                Init.Child.Type
                                                params.subinit.children
                                            )
                                      )

                              in    parentROMs
                                      [ "ld.lib.so", "vfs.lib.so", "init" ]
                                  # [ Init.ServiceRoute.parent "IO_MEM"
                                    , Init.ServiceRoute.parent "IO_PORT"
                                    , Init.ServiceRoute.parent "IRQ"
                                    , Init.ServiceRoute.parent "VM"
                                    , Init.ServiceRoute.child "Timer" "timer"
                                    , Init.ServiceRoute.child "Rtc" "rtc"
                                    , Init.ServiceRoute.child "Gui" "gui"
                                    ]
                          }
                      )
                  ]
        }
      , rom =
          Sigil.BootModules.toRomPaths
            ( Prelude.List.concat
                (Prelude.Map.Entry Text Text)
                ( Prelude.Map.values
                    Text
                    (Prelude.Map.Type Text Text)
                    params.bootManifest
                )
            )
      }
