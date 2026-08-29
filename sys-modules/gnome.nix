#/etc/nixos/sys-modules/gnome.nix
{ config, lib, pkgs, ... }:

{
  services.displayManager.gdm = {
    enable = true;
    #after = [ "systemd-udev-settle.service" ];
    #wants = [ "systemd-udev-settle.service" ];
  };

  services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [ 
    adwaita-icon-theme
    vanilla-dmz
  ];

  home-manager.users.dectec.home.pointerCursor = {
    enable = true;
    name = "Vanilla-DMZ";
    package = [ pkgs.vanilla-dmz ];
    size = 32;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "leo";
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", DRIVERS=="i915", TAG+="mutter-device-preferred-primary"
  '';
}
