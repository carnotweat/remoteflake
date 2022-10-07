{ config, pkgs, lib, ... }:

with lib;
let cfg = config.hardware.genode.framebuffer;
in {
  options.hardware.genode.framebuffer = {
    enable = lib.mkEnableOption "framebuffer driver";
    driver = mkOption {
      type = types.enum [ "boot" "vesa" ];
      default = "vesa";
    };
  };

  config = {

    hardware.genode.platform.policies = lib.optional cfg.enable
      (builtins.toFile ("framebuffer.platform-policy.dhall") ''
        let Sigil = env:DHALL_SIGIL

        in  Sigil.Init.Config.Policy::{
            , service = "Platform"
            , label = Sigil.Init.LabelSelector.prefix "fb_drv"
            , content =
              [ Sigil.Prelude.XML.leaf
                  { name = "pci", attributes = toMap { class = "VGA" } }
              ]
            }
      '');

    genode.core.children.fb_drv = mkIf cfg.enable {
      package = with pkgs.genodePackages;
        {
          boot = boot_fb_drv;
          vesa = vesa_drv;
        }.${cfg.driver};
      configFile = builtins.toFile "fb_drv.dhall" ''
        let Sigil = env:DHALL_SIGIL

        let Init = Sigil.Init

        in  λ(binary : Text) →
              Init.Child.flat
                Init.Child.Attributes::{
                , binary
                , config = Init.Config::{
                  , attributes = toMap
                      { width = "1024"
                      , height = "768"
                      }
                  }
                , resources = Init.Resources::{ caps = 256, ram = Sigil.units.MiB 32 }
                , routes =
                  [ Init.ServiceRoute.parent "IO_MEM"
                  , Init.ServiceRoute.parent "IO_PORT"
                  , Init.ServiceRoute.child "Capture" "gui"
                  ]
                }
      '';
    };

    virtualisation.graphics = lib.mkDefault cfg.enable;

  };

}
