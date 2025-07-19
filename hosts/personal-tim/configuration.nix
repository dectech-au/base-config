#/etc/nixos/hosts/personal-tim/configuration.nix
{ config, lib, pkgs, ... }:
{
  imports = [ 
    ../../hardware-configuration.nix
    ../../sys-modules/baobab.nix
    ../../sys-modules/birdtray.nix
    ../../sys-modules/bluetooth.nix
    ../../sys-modules/btrfs.nix
    ../../sys-modules/chrome.nix
    ../../sys-modules/esphome.nix
    ../../sys-modules/evolution.nix
    ../../sys-modules/firefox.nix
    ../../sys-modules/firewall.nix
    ../../sys-modules/flatpak.nix
    ../../sys-modules/fonts.nix
    ../../sys-modules/github-desktop.nix
    ../../sys-modules/gnome-disks.nix
    ../../sys-modules/gparted.nix
    ../../sys-modules/htop.nix
    ../../sys-modules/jellyfin.nix
    ../../sys-modules/kcalc.nix
    ../../sys-modules/kdeconnect-firewall.nix
    ../../sys-modules/killall.nix
    ../../sys-modules/nixpkgs-fmt.nix
    #../../sys-modules/nix-ld.nix
    ../../sys-modules/papirus-theme.nix
    ../../sys-modules/libreoffice.nix
    ../../sys-modules/morph.nix
    ../../sys-modules/nixvim.nix
    #../../sys-modules/nextcloud.nix
    ../../sys-modules/ntfs.nix
    ../../sys-modules/nvidia.nix
    ../../sys-modules/onlyoffice.nix
    ../../sys-modules/openssl.nix
    ../../sys-modules/papirus.nix
    #../../sys-modules/pinegrow.nix
    ../../sys-modules/plasma.nix
    ../../sys-modules/protonmail-bridge.nix
    #../../sys-modules/qt.nix
    ../../sys-modules/remotemouse.nix
    ../../sys-modules/signal-desktop.nix
    ../../sys-modules/sshfs.nix
		../../sys-modules/star-rail-macro.nix
    ../../sys-modules/steam.nix
    ../../sys-modules/tailscale.nix
    ../../sys-modules/teams.nix
    ../../sys-modules/teamviewer.nix
    ../../sys-modules/virtualbox.nix
		../../sys-modules/windows-reboot.nix
    # ../../sys-modules/wine.nix
    #../../sys-modules/wordpress.nix
    #./personalisation/wallpaper-service.nix
	];
  
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = false; # hostname is injected by hosts/local/host.nix - don't set
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  # services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  # services.displayManager.sddm.enable = true;
  # services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  environment.systemPackages = with pkgs; [ pulseaudio ];
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
  users.users.dectec = {
    isNormalUser = true;
    description = "dectec";
    extraGroups = [ "networkmanager" "wheel" "vboxusers" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Enable automatic login for the user.
 #  services.displayManager.autoLogin = {
	# enable = false;
 #  	user = "dectec";
 #  };
  
  # Allow unfree packages
  # nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

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
  system.stateVersion = "24.11"; # Did you read the comment?
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

}
