{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.hardware.genode;
  toDhall = lib.generators.toDhall { };
in {
  imports = [ ./ahci.nix ./framebuffer.nix ./nic.nix ./usb.nix ];

  options.hardware.genode = {
    verbose = lib.mkEnableOption "verbose drivers";
    platform.policies = lib.mkOption {
      type = with types; listOf path;
      default = [ ];
      description = ''
        List of policies to append to the Genode platform driver.
        Type is Init.Config.Policy.Type.
      '';
    };
  };

  config = let
    deviceManagerEnable = cfg.ahci.enable || cfg.usb.enable;

    ahciEris = lib.getEris "bin" pkgs.genodePackages.ahci_drv;
    partBlockEris = lib.getEris "bin" pkgs.genodePackages.part_block;

    usbEris = lib.attrsets.mapAttrs (_: lib.getEris "bin") {
      usb_block_drv = cfg.usb.storage.package;
      usb_host_drv = cfg.usb.host.package;
    };

    ahciConfig = with cfg.ahci;
      lib.optionalString enable ''
        , ahci_drv = Some ${
          toDhall {
            binary = ahciEris.cap;
            atapi = atapiSupport;
          }
        }
      '';

    usbConfig = lib.optionalString cfg.usb.enable ''
      , usb_block_drv = Some { binary = "${usbEris.usb_block_drv.cap}" }
      , usb_host_drv = Some ${
        with cfg.usb.host;
        toDhall {
          binary = usbEris.usb_host_drv.cap;
          bios_handoff = biosHandoff;
          ehci = ehciSupport;
          ohci = ohciSupport;
          uhci = uhciSupport;
          xhci = xhciSupport;
        }
      }
    '';

    managerConfig = pkgs.writeText "device_manager.dhall" ''
      let Manager = ${pkgs.genodePackages.device_manager.dhall}/package.dhall

      in  Manager.toChildAttributes
            Manager::{
            , part_block.binary = "${partBlockEris.cap}"
            ${ahciConfig}
            ${usbConfig}
            , verbose = ${toDhall cfg.verbose}
            }
    '';
  in {

    genode.core.children.acpi_drv = {
      package = pkgs.genodePackages.acpi_drv;
      configFile = ./acpi_drv.dhall;
    };

    genode.core.children.platform_drv = {
      package = pkgs.genodePackages.platform_drv;
      configFile =
        let policies = map (policy: ", ${policy}") cfg.platform.policies;
        in pkgs.writeText "platform_drv.dhall" ''
          let Sigil = env:DHALL_SIGIL

          let Init = Sigil.Init

          in  λ(binary : Text) →
                Init.Child.flat
                  Init.Child.Attributes::{
                  , binary
                  , priorityOffset = 1
                  , resources = Init.Resources::{
                    , caps = 800
                    , ram = Sigil.units.MiB 4
                    , constrainPhys = True
                    }
                  , consumeReports = [ { rom = "acpi", report = "acpi" } ]
                  , provides = [ "Platform" ]
                  , routes =
                    [ Init.ServiceRoute.parent "IRQ"
                    , Init.ServiceRoute.parent "IO_MEM"
                    , Init.ServiceRoute.parent "IO_PORT"
                    ]
                  , config = Init.Config::{
                    , policies = [ ${
                      toString policies
                    } ] : List Init.Config.Policy.Type
                    }
                  }
        '';
    };

    genode.core.children.device_manager = lib.mkIf deviceManagerEnable {
      package = pkgs.genodePackages.device_manager;
      configFile = pkgs.writeText "device_manager.dhall" ''
        let Sigil = env:DHALL_SIGIL

        in  λ(cap : Text) →
              Sigil.Init.Child.flat
                (   (${managerConfig}).device_manager
                  ⫽ { binary = cap
                    , priorityOffset = 1
                    , resources = Sigil.Init.Resources::{
                      , caps = 256
                      , ram = Sigil.units.MiB 8
                      }
                    }
                )
      '';
    };

    genode.core.children.drivers = lib.mkIf deviceManagerEnable {
      package = pkgs.genodePackages.init;
      extraErisInputs = [ partBlockEris ]
        ++ lib.optional cfg.ahci.enable ahciEris
        ++ lib.optionals cfg.usb.enable (builtins.attrValues usbEris);
      configFile = pkgs.writeText "drivers.dhall" ''
        let Sigil = env:DHALL_SIGIL

        let childAttrs = (${managerConfig}).drivers

        in  λ(cap : Text) →
              Sigil.Init.Child.flat
                (   childAttrs
                  ⫽ { binary = cap
                    , config =
                        childAttrs.config
                      with policies =
                        [ Sigil.Init.Config.Policy::{
                          , label = Sigil.Init.LabelSelector.none
                          , service = "Block"
                          }
                        ]
                    , priorityOffset = 2
                    }
                )
      '';
    };

  };

}
