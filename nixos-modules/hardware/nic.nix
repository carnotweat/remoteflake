{ config, pkgs, lib, ... }:

let
  mkUplinkDriver = { name, policyPrefix, driver, verbose }: {
    package = with pkgs.genodePackages;
      {
        ipxe = ipxe_nic_drv;
        virtio = virtio_nic_drv;
      }.${driver};
    configFile = pkgs.writeText "${name}.dhall" ''
      let Sigil = env:DHALL_SIGIL

      let Init = Sigil.Init

      in  λ(binary : Text) →
            Init.Child.flat
              Init.Child.Attributes::{
              , binary
              , resources = Init.Resources::{ caps = 128, ram = Sigil.units.MiB 4 }
              , routes = [ Init.ServiceRoute.parent "IO_MEM" ]
              , config = Init.Config::{
                , attributes = toMap { verbose = "${
                  if verbose then "yes" else "no"
                }" }
                , policies =
                  [ Init.Config.Policy::{
                    , service = "Nic"
                    , label = Init.LabelSelector.prefix "${policyPrefix}"
                    }
                  ]
                }
              }
    '';
  };

  mkUplinkDump = { name, childName, policyPrefix }: {
    package = pkgs.genodePackages.nic_dump;
    configFile = pkgs.writeText "${name}.dhall" ''
      let Sigil = env:DHALL_SIGIL

      let Init = Sigil.Init

      in  λ(binary : Text) →
            Init.Child.flat
              Init.Child.Attributes::{
              , binary
              , resources = Init.Resources::{ caps = 128, ram = Sigil.units.MiB 6 }
              , config = Init.Config::{
                , attributes = toMap { downlink = "${childName}", uplink = "driver" }
                , policies =
                  [ Init.Config.Policy::{
                    , service = "Nic"
                    , label = Init.LabelSelector.prefix "${policyPrefix}"
                    }
                  ]
                }
              }
    '';
  };

  nicDriversFor = children:
    builtins.listToAttrs (lib.lists.flatten (lib.attrsets.mapAttrsToList
      (childName:
        { uplinks, ... }:
        lib.attrsets.mapAttrsToList (uplink:
          let
            childLabel = "${childName} -> ${uplink}";
            driverName = "${childName}-${uplink}-driver";
            dumpName = "${childName}-${uplink}-dump";
          in { driver, dump, verbose, ... }:
          [(rec {
            name = driverName;
            value = mkUplinkDriver {
              inherit name driver verbose;
              policyPrefix = if dump then dumpName else childLabel;
            };
          })] ++ lib.lists.optional dump (rec {
            name = dumpName;
            value = mkUplinkDump {
              inherit name childName;
              policyPrefix = childLabel;
            };
          })) uplinks) children));

  qemuNicsFor = children:
    builtins.listToAttrs (lib.lists.flatten (lib.attrsets.mapAttrsToList
      (childName:
        { uplinks, ... }:
        lib.attrsets.mapAttrsToList (uplink:
          { driver, ... }: {
            name = "${childName}-${uplink}";
            value = {
              netdev = {
                kind = "user";
                settings = { ipv6 = "off"; };
              };
              device = {
                kind = {
                  ipxe = "e1000";
                  virtio = "virtio";
                }.${driver};
              };
            };
          }) uplinks) children));

in {

  config = {
    hardware.genode.platform.policies = let
      mkPolicy = { name, platformPolicy }:
        pkgs.writeText "${name}.policy.dhall" ''${platformPolicy} "${name}"'';

      childPolicies = prefix: children:
        builtins.concatLists (lib.attrsets.mapAttrsToList (child: childAttrs:
          lib.attrsets.mapAttrsToList (uplink: uplinkAttrs:
            mkPolicy {
              name = "${prefix}${child}-${uplink}-driver";
              inherit (uplinkAttrs) platformPolicy;
            }) childAttrs.uplinks) children);

      corePolicies = childPolicies "" config.genode.core.children;
      initPolicies = childPolicies "nixos -> " config.genode.init.children;
    in corePolicies ++ initPolicies;

    genode.core.auxiliaryChildren = nicDriversFor config.genode.core.children;
    genode.init.auxiliaryChildren = nicDriversFor config.genode.init.children;

    virtualisation.qemu.nics =
      qemuNicsFor (config.genode.core.children // config.genode.init.children);

  };
}
