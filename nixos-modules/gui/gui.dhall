let Sigil = env:DHALL_SIGIL

let Prelude = Sigil.Prelude

let Map = Prelude.Map

let Attributes = Map.Type Text Text

let XML = Prelude.XML

let Init = Sigil.Init

let forward = λ(x : Text) → { report = x, rom = x }

let Domain/Type = { name : Text, layer : Natural, attrs : Attributes }

let Domain/toXML =
      λ(domain : Domain/Type) →
        XML.leaf
          { name = "domain"
          , attributes =
                toMap
                  { name = domain.name
                  , layer = Prelude.Natural.show domain.layer
                  }
              # domain.attrs
          }

let nitpickerDomains =
      [ { name = "pointer"
        , layer = 1
        , attrs = toMap { content = "client", label = "no", origin = "pointer" }
        }
      , { name = "decorator"
        , layer = 2
        , attrs = toMap
            { content = "client"
            , label = "no"
            , focus = "click"
            , hover = "always"
            }
        }
      , { name = "other", layer = 2, attrs = toMap { content = "client" } }
      , { name = "wm"
        , layer = 3
        , attrs = toMap
            { content = "client"
            , label = "no"
            , focus = "click"
            , hover = "always"
            }
        }
      , { name = "backdrop"
        , layer = 4
        , attrs = toMap { content = "client", label = "no", backdrop = "yes" }
        }
      ]

let BinaryField = { binary : Text }

in  λ ( params
      : { decorator : BinaryField
        , window_layouter : BinaryField
        , nitpicker : BinaryField
        , pointer : BinaryField
        , wm : BinaryField
        }
      ) →
    λ(binary : Text) →
      Init.toChild
        Init::{
        , verbose = True
        , children = toMap
            { nitpicker =
                Init.Child.flat
                  Init.Child.Attributes::{
                  , binary = params.nitpicker.binary
                  , resources = Init.Resources::{ ram = Sigil.units.MiB 4 }
                  , config = Init.Config::{
                    , content =
                          [ XML.leaf
                              { name = "capture"
                              , attributes = XML.emptyAttributes
                              }
                          , XML.leaf
                              { name = "event"
                              , attributes = XML.emptyAttributes
                              }
                          , XML.leaf
                              { name = "report"
                              , attributes = toMap
                                  { hover = "yes"
                                  , focus = "yes"
                                  , clicked = "yes"
                                  , keystate = "no"
                                  , displays = "yes"
                                  , pointer = "yes"
                                  }
                              }
                          , XML.leaf
                              { name = "background"
                              , attributes = toMap { color = "#ffffff" }
                              }
                          ]
                        # Prelude.List.map
                            Domain/Type
                            XML.Type
                            Domain/toXML
                            nitpickerDomains
                    , defaultPolicy = Some Init.Config.DefaultPolicy::{
                      , attributes = toMap { domain = "other" }
                      }
                    , policies =
                      [ Init.Config.Policy::{
                        , service = "Gui"
                        , label = Init.LabelSelector.prefix "pointer"
                        , attributes = toMap { domain = "pointer" }
                        }
                      , Init.Config.Policy::{
                        , service = "Gui"
                        , label = Init.LabelSelector.prefix "decorator"
                        , attributes = toMap { domain = "decorator" }
                        }
                      , Init.Config.Policy::{
                        , service = "Gui"
                        , label = Init.LabelSelector.prefix "wm"
                        , attributes = toMap { domain = "wm" }
                        }
                      , Init.Config.Policy::{
                        , service = "Gui"
                        , label = Init.LabelSelector.suffix "backdrop"
                        , attributes = toMap { domain = "backdrop" }
                        }
                      ]
                    }
                  , provides = [ "Capture", "Event" ]
                  , consumeReports =
                    [ { rom = "focus", report = "sculpt-only?" } ]
                  , produceReports =
                      let f =
                            λ(report : Text) →
                              { report, rom = "nitpicker_" ++ report }

                      in  [ f "hover"
                          , f "clicked"
                          , f "focus"
                          , f "displays"
                          , f "pointer"
                          ]
                  }
            , pointer =
                Init.Child.flat
                  Init.Child.Attributes::{
                  , binary = params.pointer.binary
                  , config = Init.Config::{
                    , attributes = toMap { shape = "yes" }
                    }
                  , provides = [ "Report" ]
                  , consumeReports =
                    [ { rom = "hover", report = "nitpicker_hover" }
                    , forward "xray"
                    ]
                  , resources = Init.Resources::{ ram = Sigil.units.MiB 2 }
                  }
            , decorator =
                Init.Child.flat
                  Init.Child.Attributes::{
                  , binary = params.decorator.binary
                  , config = Init.Config::{
                    , content =
                        Prelude.List.map
                          Text
                          XML.Type
                          ( λ(name : Text) →
                              XML.leaf
                                { name, attributes = XML.emptyAttributes }
                          )
                          [ "maximizer", "title" ]
                    }
                  , resources = Init.Resources::{
                    , caps = 384
                    , ram = Sigil.units.MiB 12
                    }
                  , consumeReports =
                    [ forward "window_layout"
                    , { rom = "pointer", report = "wm_pointer" }
                    ]
                  , produceReports =
                    [ forward "decorator_margins"
                    , { report = "hover", rom = "decorator_hover" }
                    ]
                  }
            , layouter =
                Init.Child.flat
                  Init.Child.Attributes::{
                  , binary = params.window_layouter.binary
                  , resources = Init.Resources::{ ram = Sigil.units.MiB 4 }
                  , consumeReports =
                    [ forward "decorator_margins"
                    , forward "focus_request"
                    , { rom = "hover", report = "decorator_hover" }
                    , { rom = "rules", report = "layouter_rules" }
                    , forward "window_list"
                    ]
                  , produceReports =
                    [ forward "window_layout"
                    , forward "resize_request"
                    , { report = "focus", rom = "layouter_focus" }
                    , { report = "rules", rom = "layouter_rules" }
                    ]
                  }
            , wm =
                Init.Child.flat
                  Init.Child.Attributes::{
                  , binary = params.wm.binary
                  , config = Init.Config::{
                    , defaultPolicy = Some Init.Config.DefaultPolicy::{=}
                    , policies =
                      [ Init.Config.Policy::{
                        , service = "Gui"
                        , label = Init.LabelSelector.prefix "decorator"
                        , attributes = toMap { role = "decorator" }
                        }
                      , Init.Config.Policy::{
                        , service = "Gui"
                        , label = Init.LabelSelector.prefix "layouter"
                        , attributes = toMap { role = "layouter" }
                        }
                      ]
                    }
                  , provides = [ "Gui", "Report", "ROM" ]
                  , consumeReports =
                    [ forward "resize_request"
                    , { rom = "focus", report = "layouter_focus" }
                    ]
                  , produceReports =
                    [ forward "focus_request"
                    , { report = "pointer", rom = "wm_pointer" }
                    , forward "window_list"
                    ]
                  , resources = Init.Resources::{
                    , caps = 256
                    , ram = Sigil.units.MiB 8
                    }
                  }
            }
        , routes = [ Init.ServiceRoute.parent "Timer" ]
        , services =
          [ Init.ServiceRoute.child "Capture" "nitpicker"
          , Init.ServiceRoute.child "Event" "nitpicker"
          , Init.ServiceRoute.child "Gui" "wm"
          , Init.ServiceRoute.child "ROM" "wm"
          , Init.ServiceRoute.child "Report" "wm"
          ]
        }
        Init.Attributes::{ provides = [ "Capture", "Event", "Gui" ] }
