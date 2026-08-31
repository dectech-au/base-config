#/etc/nixos/sys-modules/gnome.nix
{ config, lib, pkgs, ... }:

{
  services.displayManager.gdm = {
    enable = true;
    #after = [ "systemd-udev-settle.service" ];
    #wants = [ "systemd-udev-settle.service" ];
  };

  services.desktopManager.gnome.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "leo";
  };

  home-manager.users.leo = {
  dconf.settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [ 
        "no-overview@fthx"
      ];
    };
  };

  #services.udev.extraRules = ''
  #  SUBSYSTEM=="drm", KERNEL=="card*", DRIVERS=="i915", TAG+="mutter-device-preferred-primary"
  #'';
}
