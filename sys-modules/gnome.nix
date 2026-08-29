#/etc/nixos/sys-modules/gnome.nix
{ ... }:

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

  #services.udev.extraRules = ''
  #  SUBSYSTEM=="drm", KERNEL=="card*", DRIVERS=="i915", TAG+="mutter-device-preferred-primary"
  #'';
}
