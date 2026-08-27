#/etc/nixos/sys-modules/gnome.nix
{ ... }:

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.displayManager.autoLogin = {
   enable = true;
   user = "leo";
  };
}
