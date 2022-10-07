let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let Prelude = Sigil.Prelude

let VFS = Sigil.VFS

let XML = Prelude.XML

let Init = Sigil.Init

let Child = Init.Child

let Resources = Init.Resources

let ServiceRoute = Init.ServiceRoute

let routeRom =
      λ(label : Text) → ServiceRoute.parentLabel "ROM" (Some "log") (Some label)

in  λ ( params
      : { fontFile : Text
        , log_core : Text
        , terminal : Text
        , terminal_log : Text
        , vfs_ttf : Text
        }
      ) →
    λ(binary : Text) →
      Init.toChild
        Init::{
        , verbose = True
        , routes = [ Init.ServiceRoute.parent "Timer" ]
        , children = toMap
            { terminal =
                Child.flat
                  Child.Attributes::{
                  , binary = params.terminal
                  , exitPropagate = True
                  , resources = Resources::{
                    , caps = 256
                    , ram = Sigil.units.MiB 4
                    }
                  , routes =
                    [ ServiceRoute.parent "Gui"
                    , ServiceRoute.parentLabel
                        "ROM"
                        (Some "vfs_ttf.lib.so")
                        (Some params.vfs_ttf)
                    ]
                  , config = Init.Config::{
                    , content =
                      [ XML.element
                          { name = "palette"
                          , attributes = toMap
                              { uri = "https://pippin.gimp.org/ametameric/"
                              , notes = "Black on white is unsupported."
                              }
                          , content =
                              let color =
                                    λ(index : Natural) →
                                    λ(value : Text) →
                                      XML.leaf
                                        { name = "color"
                                        , attributes = toMap
                                            { index = Natural/show index
                                            , value
                                            }
                                        }

                              in  [ color 0 "#000000"
                                  , color 1 "#a02929"
                                  , color 2 "#4aa08b"
                                  , color 3 "#878453"
                                  , color 4 "#2424ed"
                                  , color 5 "#ab4adf"
                                  , color 6 "#3b6bb1"
                                  , color 7 "#c3c3c3"
                                  , color 8 "#6f6f6f"
                                  , color 9 "#edac82"
                                  , color 10 "#99edba"
                                  , color 11 "#e9d808"
                                  , color 12 "#82b4ed"
                                  , color 13 "#d66fed"
                                  , color 14 "#1de1ed"
                                  , color 15 "#ffffff"
                                  ]
                          }
                      , VFS.vfs
                          [ VFS.leafAttrs
                              "rom"
                              (toMap { name = params.fontFile })
                          , VFS.dir
                              "fonts"
                              [ VFS.dir
                                  "monospace"
                                  [ VFS.leafAttrs
                                      "ttf"
                                      ( toMap
                                          { name = "regular"
                                          , path = params.fontFile
                                          , size_px = "8"
                                          }
                                      )
                                  ]
                              ]
                          ]
                      ]
                    , policies =
                      [ Init.Config.Policy::{
                        , service = "Terminal"
                        , label = Init.LabelSelector.prefix "terminal_log"
                        }
                      ]
                    }
                  }
            , terminal_log =
                Child.flat
                  Child.Attributes::{
                  , binary = params.terminal_log
                  , config = Init.Config::{
                    , content =
                      [ XML.leaf
                          { name = "initial"
                          , attributes = toMap
                              { width = "600"
                              , height = "400"
                              , info = "defaults to 1x1"
                              }
                          }
                      ]
                    , policies =
                      [ Init.Config.Policy::{
                        , service = "LOG"
                        , label = Init.LabelSelector.prefix "core_log -> log"
                        , attributes = toMap { log_label = "[core] " }
                        }
                      , Init.Config.Policy::{
                        , service = "LOG"
                        , label = Init.LabelSelector.prefix "kernel_log -> log"
                        , attributes = toMap { log_label = "[kernel] " }
                        }
                      ]
                    }
                  }
            , core_log =
                Child.flat
                  Child.Attributes::{
                  , binary = params.log_core
                  , priorityOffset = 1
                  , routes = [ routeRom "core_log" ]
                  }
            , kernel_log =
                Child.flat
                  Child.Attributes::{
                  , binary = params.log_core
                  , priorityOffset = 1
                  , routes = [ routeRom "kernel_log" ]
                  }
            }
        }
        Init.Attributes::{
        , binary
        , routes = [ Init.ServiceRoute.child "Gui" "gui" ]
        }
