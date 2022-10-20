{-
Storage device info can be found using the command:
  lsblk -o NAME,MODEL,SERIAL,PARTUUID,LABEL
-}

let Genode = ./Genode.dhall

let XML = Genode.Prelude.XML

let Configuration = ./Configuration.dhall

let Block = ./block/package.dhall

let Framebuffer = ./framebuffer/package.dhall

let Storage = ./storage/package.dhall

let cfg
    : Configuration
    = { block = Block.Type.Ahci {=}
      , framebuffer =
          Framebuffer.Type.Vesa
            { buffered = False
            , depth = 16
            , mode = Some Framebuffer.Mode.default
            }
      , storage = Storage.Type.Ext2 {=}
      , input.filterConfig =
          let key =
                  λ(name : Text)
                → XML.leaf { name = "key", attributes = toMap { name = name } }

          let remap =
                  λ(name : Text)
                → λ(to : Text)
                → XML.leaf
                    { name = "key"
                    , attributes = toMap { name = name, to = to }
                    }

          in  Genode.Init.Config::{
              , content =
                [ XML.text "<input label=\"ps2\"/>"
                , XML.element
                    { name = "output"
                    , attributes = XML.emptyAttributes
                    , content =
                      [ XML.element
                          { name = "chargen"
                          , attributes = XML.emptyAttributes
                          , content =
                                [ XML.element
                                    { name = "remap"
                                    , attributes = XML.emptyAttributes
                                    , content =
                                      [ remap "KEY_LEFTMETA" "KEY_SCREEN"
                                      , XML.leaf
                                          { name = "input"
                                          , attributes = toMap { name = "ps2" }
                                          }
                                      ]
                                    }
                                , XML.element
                                    { name = "mod1"
                                    , attributes = XML.emptyAttributes
                                    , content =
                                      [ key "KEY_LEFTSHIFT"
                                      , key "KEY_RIGHTSHIFT"
                                      ]
                                    }
                                , XML.element
                                    { name = "mod2"
                                    , attributes = XML.emptyAttributes
                                    , content =
                                      [ key "KEY_LEFTCTRL"
                                      , key "KEY_RIGHTCTRL"
                                      ]
                                    }
                                , XML.element
                                    { name = "mod3"
                                    , attributes = XML.emptyAttributes
                                    , content = [ key "KEY_RIGHTALT" ]
                                    }
                                ]
                              # ./workman.map.dhall
                          }
                      ]
                    }
                ]
              }
      }

let stage2 = ./stage2.dhall

let stage1 = ./stage1.dhall cfg

let stage0 = ./stage0.dhall cfg stage1

in  { stage0 = stage0, stage1 = stage1, stage2 = stage2 }
