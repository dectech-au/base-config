#~/.dotfiles/modules/start-menu/start-onlyoffice.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.only-office = {
    name = "ONLYOFFICE";
    exec = "onlyoffice-desktopeditors";
    icon = "wps-office-wpsmain";
    terminal = false;
    type = "Application";
    categories = [ "Office" ];
  };
}
