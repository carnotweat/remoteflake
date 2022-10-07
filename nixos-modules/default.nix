{ flake }:

{

  x86_64 = {
    imports = [
      ./eris
      ./file-systems.nix
      ./genode-core.nix
      ./genode-init.nix
      ./gui
      ./hardware
      ./qemu-vm.nix
      ./services
    ];
    nixpkgs = rec {
      localSystem.system = "x86_64-linux";
      crossSystem.system = "x86_64-genode";
      system = localSystem.system + "-" + crossSystem.system;
      pkgs = flake.legacyPackages.${system};
    };
  };

  nova = import ./nova.nix;

}
