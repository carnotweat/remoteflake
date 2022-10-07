{ config, pkgs, lib, ... }:

let
  toDhall = lib.generators.toDhall { };
  cfg = config.genode.gui;
in {
  options.genode.gui = {
    enable = lib.mkEnableOption "Genode Gui service";
    consoleLog = {
      enable = lib.mkEnableOption "console log";
      layer = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1;
      };
    };

    policies = lib.mkOption {
      type = with lib.types; listOf path;
      default = [ ];
      description = ''
        List of policies to append to the Genode GUI server.
        Type is Init.Config.Policy.Type.
      '';
    };

    domains = lib.mkOption {
      type = with lib.types; attrsOf (attrsOf str);
      description = ''
        List of domains to configure at the Gui server.
        Partially documented at the Nitpicker README,
        consult the implementation when in doubt.
        <link xlink:href="https://github.com/genodelabs/genode/blob/master/repos/os/src/server/nitpicker/README"/>
      '';
      example = {
        pointer = {
          layer = "1";
          content = "client";
          label = "no";
          origin = "pointer";
        };
        default = {
          layer = "2";
          color = "#052944";
          hover = "always";
          focus = "click";
        };
      };
    };

  };

  config = {

    genode.gui.enable = lib.mkDefault cfg.consoleLog.enable;

    genode.gui.policies = lib.optional cfg.consoleLog.enable
      (builtins.toFile ("consoleLog-gui-policy.dhall") ''
        let Init = (env:DHALL_SIGIL).Init

        in  Init.Config.Policy::{
            , service = "Gui"
            , label = Init.LabelSelector.prefix "consoleLog"
            , attributes = toMap { domain = "consoleLog" }
            }
      '');

    genode.gui.domains.consoleLog = lib.mkIf cfg.consoleLog.enable {
      layer = toString cfg.consoleLog.layer;
      content = "client";
    };

    hardware.genode.framebuffer.enable = cfg.enable;

    genode.core.children.gui = lib.mkIf cfg.enable (let
      eris = with pkgs.genodePackages;
        lib.attrsets.mapAttrs (_: lib.getEris "bin") {
          inherit decorator window_layouter wm;
        } // (let nitpick = lib.getEris' "bin" nitpicker;
        in {
          nitpicker = nitpick "nitpicker";
          pointer = nitpick "pointer";
        });
    in {
      package = pkgs.genodePackages.init;
      extraErisInputs = builtins.attrValues eris;
      configFile = pkgs.writeText "gui.dhall" ''
        ${./gui.dhall} ${
          toDhall
          (lib.attrsets.mapAttrs (_: value: { binary = value.cap; }) eris)
        }
      '';
    });

    genode.core.romModules = lib.mkIf cfg.consoleLog.enable {
      "FiraCode-VF.ttf" = pkgs.buildPackages.fira-code
        + "/share/fonts/truetype/FiraCode-VF.ttf";
    };

    genode.core.children.consoleLog = lib.mkIf cfg.consoleLog.enable (let
      erisInputs = (lib.attrsets.mapAttrs (_: lib.getEris "bin") {
        inherit (pkgs.genodePackages) log_core terminal terminal_log;
      }) // (lib.attrsets.mapAttrs (_: lib.getEris "lib") {
        inherit (pkgs.genodePackages) vfs_ttf;
      });
    in {
      package = pkgs.genodePackages.init;
      coreROMs = [ "core_log" "kernel_log" ];
      extraErisInputs = builtins.attrValues erisInputs;
      configFile = pkgs.writeText "consoleLog.dhall" ''
        ${./consoleLog.dhall} ${
          toDhall (lib.attrsets.mapAttrs (_: builtins.getAttr "cap") erisInputs
            // {
              fontFile = "FiraCode-VF.ttf";
            })
        }
      '';
    });

  };
}
