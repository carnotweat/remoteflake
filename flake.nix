# References:
#
# https://github.com/cmacrae/config
# https://www.tweag.io/blog/2020-05-25-flakes/
# https://www.tweag.io/blog/2020-06-25-eval-cache/
# https://www.tweag.io/blog/2020-07-31-nixos-flakes/

{
  description = "nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
#    darwin.url = "github:lnl7/nix-darwin";
#    home-manager.url = "github:nix-community/home-manager";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    mozilla.url = "github: mozilla /nixpkgs-mozilla";

    # Follows
#    darwin.inputs.nixpkgs.follows = "nixpkgs";
#    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, emacs-overlay }:
    let
      overlays = [
        emacs-overlay.overlay
        mozilla.overlay
#        (import ./nix/overlays)
      ];
    in {
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
    #   darwinConfigurations.d12frosted = darwin.lib.darwinSystem {
    #     system = "aarch64-darwin"; # "x86_64-darwin";
           modules = [
    #         ./nix/darwin.nix
             ./configuration.nix
          #  home-manager.darwinModules.home-manager
          # {
          #   nixpkgs.overlays = overlays;
          # }
        ];
      };

      # homeConfigurations.borysb = home-manager.lib.homeManagerConfiguration {
      #   configuration = { pkgs, lib, config, ... }: {
      #     imports = [
      #       ./nix/home.nix
      #       ./nix/linux/xsession.nix
      #       ./nix/linux/services.nix
      #     ];
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = overlays;
#        };
        system = "x86_64-linux";
        homeDirectory = "/home/x";
        username = "x";
      };
}
