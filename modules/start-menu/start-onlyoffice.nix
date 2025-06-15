#~/.dotfiles/modules/start-menu/start-onlyoffice.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.ONLYOFFICE = {
    name = "Office";
    #description = "Document Editor";
    comment = "Edit office documents";
    exec = "onlyoffice-desktopeditors %U";
    icon = "ms-office";
    terminal = false;
    type = "Application";
    categories = [ "Office" ];
  };
}
