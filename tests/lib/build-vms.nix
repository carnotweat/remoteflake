{ system, localSystem, crossSystem
# Nixpkgs, for qemu, lib and more
, pkgs, lib, modulesPath
# NixOS configuration to add to the VMs
, extraConfigurations ? [ ] }:

with pkgs.lib;
with import ./qemu-flags.nix { inherit pkgs; };

rec {

  inherit pkgs;

  qemu = pkgs.buildPackages.buildPackages.qemu_test;

  # Build a virtual network from an attribute set `{ machine1 =
  # config1; ... machineN = configN; }', where `machineX' is the
  # hostname and `configX' is a NixOS system configuration.  Each
  # machine is given an arbitrary IP address in the virtual network.
  buildVirtualNetwork = nodes:
    let nodesOut = mapAttrs (_: buildVM nodesOut) (assignIPAddresses nodes);
    in nodesOut;

  buildVM = nodes: configurations:

    import "${modulesPath}/../lib/eval-config.nix" {
      inherit lib system;
      modules = configurations ++ extraConfigurations;
      baseModules = (import "${modulesPath}/module-list.nix") ++ [
        ../../nixos-modules/eris
        ../../nixos-modules/file-systems.nix
        ../../nixos-modules/genode-core.nix
        ../../nixos-modules/genode-init.nix
        ../../nixos-modules/gui
        ../../nixos-modules/hardware
        ../../nixos-modules/qemu-vm.nix
        ../../nixos-modules/services
        {
          key = "qemu";
          system.build.qemu = qemu;
        }
        {
          key = "nodes";
          _module.args.nodes = nodes;
        }
        {
          system.build.qemu = qemu;
          nixpkgs = { inherit system crossSystem localSystem pkgs; };
        }
      ];
    };

  # Given an attribute set { machine1 = config1; ... machineN =
  # configN; }, sequentially assign IP addresses in the 192.168.1.0/24
  # range to each machine, and set the hostname to the attribute name.
  assignIPAddresses = nodes:

    let

      machines = attrNames nodes;

      machinesNumbered = zipLists machines (range 1 254);

      nodes_ = forEach machinesNumbered (m:
        nameValuePair m.fst [
          ({ config, nodes, ... }:
            let
              interfacesNumbered =
                zipLists config.virtualisation.vlans (range 1 255);
              interfaces = forEach interfacesNumbered ({ fst, snd }:
                nameValuePair "eth${toString snd}" {
                  ipv4.addresses = [{
                    address = "192.168.${toString fst}.${toString m.snd}";
                    prefixLength = 24;
                  }];
                  # genode.driver = "virtio";
                });
            in {
              key = "ip-address";
              config = {
                networking.hostName = mkDefault m.fst;

                networking.interfaces = listToAttrs interfaces;

                networking.primaryIPAddress = optionalString (interfaces != [ ])
                  (head (head interfaces).value.ipv4.addresses).address;

                # Put the IP addresses of all VMs in this machine's
                # /etc/hosts file.  If a machine has multiple
                # interfaces, use the IP address corresponding to
                # the first interface (i.e. the first network in its
                # virtualisation.vlans option).
                networking.hosts = mapAttrs' (name: machine:
                  let config = machine.config;
                  in {
                    name = config.networking.primaryIPAddress;
                    value = optional (config.networking.domain != null)
                      "${config.networking.hostName}.${config.networking.domain}"
                      ++ [ config.networking.hostName ];
                  }) nodes;

                virtualisation.qemu.options = forEach interfacesNumbered
                  ({ fst, snd }: qemuNICFlags snd fst m.snd);
              };
            })
          (getAttr m.fst nodes)
        ]);

    in listToAttrs nodes_;

}
