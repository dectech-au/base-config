#/etc/nixos/sys-modules/gnome.nix
{ pkgs, ... }:
{
  services.xserver.enable = true;

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  services.desktopManager.gnome.enable = true;
  services.displayManager.defaultSession = "gnome";

  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    gnome-maps
    gnome-music
    gnome-tour
    totem
  ];
}
