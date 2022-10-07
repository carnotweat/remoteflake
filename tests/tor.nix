{
  name = "tor";
  machine = {

    documentation.nixos = {
      enable = true;
      includeAllModules = true;
    };

    environment.defaultPackages = { };

    genode.core.storeBackend = "fs";
    hardware.genode.usb.storage.enable = true;

    services.tor = {
      enable = true;
      client.enable = false;
      extraConfig = "Log [general,net,config,fs]debug stdout";
      relay = {
        enable = true;
        role = "relay";
        bridgeTransports = [ ];
      };
    };

    virtualisation.memorySize = 768;

  };
}
