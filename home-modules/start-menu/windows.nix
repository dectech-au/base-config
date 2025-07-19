#/etc/nixos/home-modules/start-menu/windows.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.Windows = {
    name = "Windows";
    comment = "Restart to Windows";
    exec = "kitty -e sudo systemctl reboot --boot-loader-entry=auto-windows";
    icon = "distributor-logo-windows";
    terminal = true;
    type = "Application";
    categories = [ "System" ];
  };
}
