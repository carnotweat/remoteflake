{ config, lib, pkgs, ... }:

let toDhall = lib.generators.toDhall { };
in {
  config = lib.mkIf config.services.tor.enable {

    genode.init.children.tor = let
      args = lib.strings.splitString " "
        config.systemd.services.tor.serviceConfig.ExecStart;
      tor' = lib.getEris' "bin" pkgs.tor "tor";
      lwip' = lib.getEris "lib" pkgs.genodePackages.vfs_lwip;
      pipe' = lib.getEris "lib" pkgs.genodePackages.vfs_pipe;
    in {
      binary = builtins.head args;
      package = pkgs.tor;
      extraErisInputs = [ tor' lwip' pipe' ];
      configFile = pkgs.writeText "tor.dhall" "${./tor.dhall} ${toDhall args} ${
          toDhall {
            lwip = lwip'.cap;
            pipe = pipe'.cap;
          }
        }";
      uplinks.uplink.driver = "ipxe";
    };

  };
}
