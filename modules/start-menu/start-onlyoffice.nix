#~/.dotfiles/modules/start-menu/start-onlyoffice.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.only-office = {
    name = "ONLYOFFICE";
    exec = "onlyoffice-desktopeditors";
    icon = "ms-office";
    terminal = false;
    type = "Application";
    categories = [ "Office" ];
  };
}
