#/etc/nixos/home-modules/start-menu/windows.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.Windows = {
    name = "Windows";
    comment = "Restart to Windows";
    exec = "${pkgs.systemctl} reboot --boot-loader-entry=auto-windows";
    icon = "distributor-logo-windows";
    terminal = false;
    type = "Application";
    categories = [ "System" ];
  };
}
