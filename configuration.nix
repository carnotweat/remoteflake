{ config, pkgs, options, ... }:
# # definitions
let
  unstable = import
    (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/db25c4da285.tar.gz)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
in
{
  environment.systemPackages = with pkgs; [
    unstable.emacs
    nginx
    tetex
    bibtex2html
    rubber
    bibtex2html
    gnupg
    hci
    libtool
    nix-prefetch-docker
    sqlite
    tinc_pre
    zlib
    poppler
    gcc
    automake
    cmake
    gnumake
    autoconf
    hy
    nox
    stack
    cabal-install
#    android-tools
    unstable.certbot
    unstable.nixops
    firefox
    pmbootstrap
    git
    gnumake
    killall
    streamlink
    home-manager
    #osquery
    python27Full
    python39Full
    
  ];


  imports =
    
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Nix_Path

  nix.nixPath = [
  "nixpkgs=${toString pkgs.path}"
];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

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
  services.autorandr.enable = true;
  services.acpid.enable = true;
  services.acpid.lidEventCommands = "/run/current-system/sw/bin/autorandr --batch --change";
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };




  # Enable CUPS to print documents.
  services.printing.enable = true;

  #allow unfree
#  allowUnfree = true;

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
    extraGroups = [ "networkmanager" "wheel" ];
    # packages = with pkgs; [
      
    #   nixopsUnstable
    # ];
  };

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "x";
  #virtualbox
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "x" "root" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "python2.7-pyjwt-1.7.1"
  ];

  #virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;  
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.x11 = true;

  

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
   #environment.systemPackages = with pkgs; [
  # #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  # #  wget
  #   git
  #   killall
  #   #ghc
  #   emacs
  #   #cabal2nix
  #   #haskellPackages.ghcid
  #   #haskellPackages.hakyll
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs.gnupg.agent.pinentryFlavor = "emacs";
  programs.gnupg.agent.enable = true;
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
    # grafana configuration
  services.grafana = {
    enable = true;
    domain = "grafana.pele";
    port = 2342;
    addr = "127.0.0.1";
  };
    # nginx reverse proxy
  services.nginx.virtualHosts.${config.services.grafana.domain} = {
    locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
        proxyWebsockets = true;
    };
  };
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
