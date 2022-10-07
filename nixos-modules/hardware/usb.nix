{ config, pkgs, lib, ... }:

with lib;
let
  mkEnableOption' = text: default:
    lib.mkEnableOption text // {
      inherit default;
    };
in {

  options.hardware.genode.usb = {
    enable = lib.mkEnableOption "USB driver";

    host = {
      package = lib.mkOption {
        type = types.package;
        default = pkgs.genodePackages.usb_host_drv;
        description = "USB host driver package.";
      };
      biosHandoff = mkEnableOption' "perform the BIOS handoff procedure" true;
      ehciSupport = mkEnableOption' "EHCI support" true;
      ohciSupport = mkEnableOption' "OHCI support" true;
      uhciSupport = mkEnableOption' "UHCI support" true;
      xhciSupport = mkEnableOption' "XHCI support" true;
    };

    storage = {
      enable = lib.mkEnableOption "USB mass storage driver";
      package = lib.mkOption {
        type = types.package;
        default = pkgs.genodePackages.usb_block_drv;
        description = "USB mass storage driver package.";
      };
    };

  };

  config = let cfg = config.hardware.genode.usb;
  in {

    hardware.genode.usb.enable = lib.mkDefault cfg.storage.enable;

    hardware.genode.platform.policies = lib.optional cfg.enable
      (builtins.toFile ("usb.platform-policy.dhall") ''
        let Sigil = env:DHALL_SIGIL

        in  Sigil.Init.Config.Policy::{
            , service = "Platform"
            , label = Sigil.Init.LabelSelector.prefix "drivers -> usb"
            , content =
              [ Sigil.Prelude.XML.leaf
                  { name = "pci", attributes = toMap { class = "USB" } }
              ]
            }
      '');

    virtualisation.qemu.options = lib.optional cfg.enable
      (lib.optional (pkgs.stdenv.isi686 || pkgs.stdenv.isx86_64) "-usb"
        ++ lib.optional (pkgs.stdenv.isAarch32 || pkgs.stdenv.isAarch64)
        "-device usb-ehci,id=usb0");

  };

}
