#~/.dotfiles/modules/start-menu/update.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.update = {
    name = "Update";
    #description = "";
    comment = "Update System";
    exec = "/run/current-system/sw/bin/nixos-rebuild";
    icon = "update-notifier";
    terminal = true;
    type = "Application";
    categories = [ "System" ];
  };
}
