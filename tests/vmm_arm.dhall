let Sigil =
        env:DHALL_SIGIL
      ? https://git.sr.ht/~ehmry/dhall-sigil/blob/trunk/package.dhall

let XML = Sigil.Prelude.XML

let Init = Sigil.Init

let ServiceRoute = Init.ServiceRoute

let Child = Init.Child

in  λ(guest : { linux : Text, dtb : Text, initrd : Text }) →
      let init =
            Init::{
            , children = toMap
                { nic =
                    Child.flat
                      Child.Attributes::{
                      , binary = "nic_router"
                      , config = Init.Config::{
                        , content =
                          [ XML.element
                              { name = "domain"
                              , attributes = toMap
                                  { name = "default"
                                  , interface = "10.0.1.1/24"
                                  }
                              , content =
                                [ XML.leaf
                                    { name = "dhcp-server"
                                    , attributes = toMap
                                        { ip_first = "10.0.1.2"
                                        , ip_last = "10.0.1.254"
                                        }
                                    }
                                ]
                              }
                          ]
                        , defaultPolicy = Some Init.Config.DefaultPolicy::{
                          , attributes = toMap { domain = "default" }
                          }
                        }
                      , provides = [ "Nic" ]
                      , resources = Init.Resources::{ ram = Sigil.units.MiB 8 }
                      }
                , earlycon =
                    Child.flat
                      Child.Attributes::{
                      , binary = "log_terminal"
                      , provides = [ "Terminal" ]
                      }
                , terminal_crosslink =
                    Child.flat
                      Child.Attributes::{
                      , binary = "terminal_crosslink"
                      , provides = [ "Terminal" ]
                      }
                , vmm =
                    Child.flat
                      Child.Attributes::{
                      , binary = "vmm"
                      , resources = Init.Resources::{
                        , caps = 256
                        , ram = Sigil.units.MiB 256
                        }
                      , routes =
                        [ ServiceRoute.parent "VM"
                        , ServiceRoute.child "Nic" "nic"
                        , ServiceRoute.childLabel
                            "Terminal"
                            "earlycon"
                            (Some "earlycon")
                            (None Text)
                        , ServiceRoute.child "Terminal" "terminal_crosslink"
                        ]
                      }
                , vm =
                    Child.flat
                      Child.Attributes::{
                      , binary = "test-terminal_expect_send"
                      , config = Init.Config::{
                        , attributes = toMap
                            { expect = "/ #", send = "ls", verbose = "yes" }
                        }
                      , routes =
                        [ ServiceRoute.child "Terminal" "terminal_crosslink" ]
                      }
                }
            , routes = [ ServiceRoute.parent "Timer" ]
            }

      in  Test::{
          , children = Test.initToChildren init
          , rom = Sigil.Boot.toRomPaths (toMap guest)
          }
