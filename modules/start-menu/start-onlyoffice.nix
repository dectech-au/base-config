#~/.dotfiles/modules/start-menu/start-onlyoffice.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.only-office = {
    name = "OnlyOffice";
    exec = "onlyoffice-desktopeditors";
    icon = "wps-office2019";
    terminal = false;
    type = "Application";
    categories = [ "Office" ];
  };
}
