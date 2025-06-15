#~/.dotfiles/modules/start-menu/teams.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.teams = {
    name = "Teams";
    #description = "";
    comment = "Unofficial Microsoft Teams client for Linux";
    exec = "teams-for-linux";
    icon = "teams-for-linux";
    terminal = false;
    type = "Application";
    categories = [ "X-Internet" ];
  };
}
