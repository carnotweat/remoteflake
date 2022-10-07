{ config, lib, ... }:

with lib;

{
  options.hardware.genode.ahci = {
    enable = lib.mkEnableOption "AHCI (SATA) block driver";
    atapiSupport = lib.mkEnableOption "ATAPI support";
  };

  config = let cfg = config.hardware.genode.ahci;
  in {

    hardware.genode.platform.policies = lib.optional cfg.enable
      (builtins.toFile ("ahci.platform-policy.dhall") ''
        let Sigil = env:DHALL_SIGIL

        in  Sigil.Init.Config.Policy::{
            , service = "Platform"
            , label = Sigil.Init.LabelSelector.prefix "drivers -> ahci"
            , content =
              [ Sigil.Prelude.XML.leaf
                  { name = "pci", attributes = toMap { class = "AHCI" } }
              ]
            }
      '');

  };

}
