{
  description = "NixOS configuration with two or more channels";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11"; 
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    netkit.url = "github:icebox-nix/netkit.nix";
    #input.netkit.url = "path:/root/clones/netkit.nix";
    # disko.url = "github:nix-community/disko";
    # disko.inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = { self, netkit,  nixpkgs, nixpkgs-unstable }:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        # use this variant if unfree packages are needed:
        # unstable = import nixpkgs-unstable {
        #   inherit system;
        #   config.allowUnfree = true;
        # };

      };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Overlays-module makes "pkgs.unstable" available in configuration.nix
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
          ./configuration.nix
          #nixosModule.disko
          #./modules/netkit.nix
          #netkit.nixosModule
        ];
      };
    };
  
  
  #     inputs.flake-compat = {
  #   url = "github:edolstra/flake-compat";
  #   flake = false;
  # };
}
