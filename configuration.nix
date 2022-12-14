# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, options, ... }:
let
    nixosRecentCommitTarball =
    builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/46ee37ca1d9cd3bb18633b4104ef21d9035aac89.tar.gz"; # 2021-09-18
      # to find this, click on "commits" at https://github.com/NixOS/nixpkgs and then follow nose to get e.g. https://github.com/NixOS/nixpkgs/commit/0e575a459e4c3a96264e7a10373ed738ec1d708f, and then change "commit" to "archive" and add ".tar.gz"
    };
    in
{
  imports =
    
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
#   #define nix-packages
    nixpkgs.config = {
      packageOverrides = pkgs: {
        nixosRecentCommit = import nixosRecentCommitTarball {
          config = config.nixpkgs.config;
        };
      };
    };
  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.kernelModules = [ "kvm-intel" ];
#define nix
  nix = {
  package = pkgs.nixFlakes;
  extraOptions = "experimental-features = nix-command flakes";
  binaryCaches          = [ "https://cache.iog.io"
                            "https://aseipp-nix-cache.global.ssl.fastly.net"
                          ];
                          
  # binaryCachePublicKeys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.supportedLocales = [ "all" ];
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  #services.xserver.layout = us;
  services.xserver.windowManager.i3.enable = true;
  #peerix
  services.postgresql.enable = true;
  # services.ipfs.enable = true;
  # services.peerix.openFirewall = true;
  # # services.peerix.user = root;
  # # services.peerix.group = wheel;
  # services.peerix.privateKeyFile = /root/.ssh/id_ed25519;
  # services.peerix.publicKeyFile = /root/.ssh/id_ed25519.pub;
  services.ipfs = {
  enable = true;
};
  #emacs
  #nixpkgs.overlays = [ nur.overlay ];
  #services.emacs.package = pkgs.emacsUnstable;
  #nixpkgs.overlays = [ (import self.inputs.emacs-overlay) ];
  #nix.settings.experimental-features = nix-command flakes;
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # docker
  virtualisation.docker.enable = true;
  
  #virtd
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  #environment.systemPackages = with pkgs; [ virt-manager ];
  #vitrualbox 
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "root"
                                          "x"
                                        ];
  nixpkgs.config.allowUnfree = true;
  #virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.x11 = true;

  #remote

  services.x2goserver.enable = true;
  

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };




  # Enable CUPS to print documents.
  services.printing.enable = true;

  #allow unfree
  #allowUnfree = true;
              nixpkgs.config.permittedInsecurePackages = [
                "python2.7-pyjwt-1.7.1"
              ];

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.x = {
    isNormalUser = true;
    description = "x";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "docker" ];
    # packages = with pkgs; [
    #   firefox
    # #git
    # #  thunderbird
    # ];
  };
  
  users.users.root.extraGroups = [ "docker" "lobvirtd"];
  #users.users.x.extraGroups = [ "docker" ];

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "x";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
     systemd.services."tigervnc-server" =                                                                                            
   { description = "TigerVNC Server";                                                                                              
                                                                                                                                   
     wantedBy = [ "multi-user.target" ];                                                                                           
                                                                                                                                   
     serviceConfig =                                                                                                               
     { StandardError = "journal";                                                                                                  
       ExecStart = ''                                                                                                              
         ${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment} ; \                                                
                   exec $SHELL --login -c "exec ${pkgs.tigervnc}/bin/vncserver :5"'                                                
       '';                                                                                                                         
       Type = "forking";                                                                                                           
       User = "x";                                                                                                             
       Restart = "always";                                                                                                         
       RestartSec = "10s";                                                                                                         
     };                                                                                                                            
   };                             
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    pkgs.unstable.nixops
    nix-serve
    pkgs.unstable.emacs
    git
    gist
    mercurial
    darcs
    libvirt
    virt-manager
    wget
    tmux
    #wemux
    tmate
    screen
    service-wrapper
    jq
    curl
    xclip
    openssl
    
    #xe-guest-utilities
    nixos-option
    sqlite
    postgresql
    nyxt
    vagrant
    docker-compose
    docker-client
    docker
    niv
    parallel
    gcc
    gmp
    xen
    busybox
    nixosRecentCommit.etcher
    fuse-emulator
    #libgmp
    #nixos.chez
    autoconf
    autogen
    automake
    gnumake
    gnum4
    pkg-config
    firefox
    #termite
    tigervnc
    x2goclient
    killall
    #engelsystem
    python39Packages.bootstrapped-pip
    python39Packages.sqlalchemy-migrate
    #python310
    python39
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  #Enable the OpenSSH daemon.
  #services.oppeenssh.enable = true;
  services.sshd.enable = true;


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.extraHosts =
  ''
199.232.28.133 raw.githubusercontent.com
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
