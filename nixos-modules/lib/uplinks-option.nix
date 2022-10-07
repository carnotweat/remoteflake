{ lib }:
with lib;

mkOption {
  default = { };
  type = with types;
    attrsOf (submodule {
      options = {
        driver = mkOption { type = types.enum [ "ipxe" "virtio" ]; };
        dump = mkEnableOption "packet logging";
        platformPolicy = mkOption {
          type = types.path;
          default = builtins.toFile "driver.policy.dhall" ''
            let Sigil = env:DHALL_SIGIL

            in  λ(driverName : Text) →
                  Sigil.Init.Config.Policy::{
                  , service = "Platform"
                  , label = Sigil.Init.LabelSelector.prefix driverName
                  , content =
                    [ Sigil.Prelude.XML.leaf
                        { name = "pci", attributes = toMap { class = "ETHERNET" } }
                    ]
                  }
          '';
        };
        verbose = lib.mkEnableOption "verbose driver logging";
      };
    });
}
