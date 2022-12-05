  netkit = {
     clash = {
       enable = true;
       redirPort =
         7892; # This must be the same with the one in your clash.yaml
     };
  
     wifi-relay = {
       interface = "wlp0s20f3"; # Change according to your device
       ssid = "netkit.nix";
       passphrase = "88888888";
     };
  
     xmm7360 = {
  	 enable = true;
       autoStart = true;
       config = {
         mycard = {
           apn = "3gnet";
           nodefaultroute = false;
           noresolv = true;
         };
       };
       package = pkgs.xmm7360-pci_5_7;
     };
  };
