{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.genode.init;

  children' = config.lib.children.freeze
    (config.genode.init.children // config.genode.init.auxiliaryChildren);

in {

  options.genode.init = {

    verbose = mkEnableOption "verbose logging";

    configFile = mkOption {
      description = ''
        Dhall configuration of this init instance after children have been merged.
      '';
      type = types.path;
    };

    baseConfig = mkOption {
      description =
        "Dhall configuration of this init instance before merging children.";
      type = types.str;
      default = ''
        let Sigil = env:DHALL_SIGIL

        in  Sigil.Init::{
            , routes =
              [ Sigil.Init.ServiceRoute.parent "File_system"
              , Sigil.Init.ServiceRoute.parent "Gui"
              , Sigil.Init.ServiceRoute.parent "IO_MEM"
              , Sigil.Init.ServiceRoute.parent "IO_PORT"
              , Sigil.Init.ServiceRoute.parent "IRQ"
              , Sigil.Init.ServiceRoute.parent "Platform"
              , Sigil.Init.ServiceRoute.parent "Rtc"
              , Sigil.Init.ServiceRoute.parent "Terminal"
              , Sigil.Init.ServiceRoute.parent "Timer"
              ]
            }
      '';
    };

    children = config.lib.types.children {
      extraOptions = {

        routeToNics = lib.mkOption {
          type = with types; listOf str;
          default = [ ];
          example = [ "eth0" ];
          description = ''
            Grant access to these Nic interfaces.
          '';
        };

        fsPersistence = lib.mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether this child will have access to mutable and persistent storage.
            This space is shared among all components for which this option is available
            and UNIX permission bits are not honored.
          '';
        };
      };
    };

    auxiliaryChildren = config.lib.types.children { extraOptions = { }; } // {
      internal = true;
      description = ''
        Children added to support other children, such as drivers.
        Do not manually add children here.
      '';
    };

    romModules = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = "Attr set of initial ROM modules";
    };

  };

  config.genode.init = {

    configFile = let

      children = lib.mapAttrsToList
        (name: value: '', { mapKey = "${name}", mapValue = ${value.config} }'')
        children';

      nicRoutes = lib.mapAttrsToList (child: value:
        (map (label: ''
          , { service =
              { name = "Nic"
              , label = Sigil.Init.LabelSelector.prefix "${child} -> ${label}"
              }
            , route = Sigil.Init.Route.parent (None Text)
            }
        '') value.routeToNics)) config.genode.init.children;

    in pkgs.writeText "init.dhall" ''
      let Sigil = env:DHALL_SIGIL

      let Init = Sigil.Init

      let baseConfig = ${cfg.baseConfig}

      in baseConfig // {
        , verbose = ${if config.genode.init.verbose then "True" else "False"}
        , children = baseConfig.children # ([ ${
          toString children
        } ] : Init.Children.Type)
        , routes = baseConfig.routes # ([${
          toString nicRoutes
        }] : List Init.ServiceRoute.Type)
      } : Init.Type
    '';

    romModules = with builtins;
      listToAttrs (lib.lists.flatten
        (map ({ roms, ... }: roms) (lib.lists.flatten (attrValues children'))));

  };

}
