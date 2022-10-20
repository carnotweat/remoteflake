let Genode = ../../Genode.dhall

let Init = Genode.Init

let ServiceRoute = Init.ServiceRoute

let Child = Init.Child

in    λ(cfg : {})
    → Child.flat
        Child.Attributes::{
        , binary = "fb_boot_drv"
        , provides = [ "Framebuffer" ]
        , routes = [ ServiceRoute.parent "IO_MEM" ]
        }
