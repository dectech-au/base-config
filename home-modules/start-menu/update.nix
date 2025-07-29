#~/.dotfiles/modules/start-menu/update.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.teams = {
    name = "Update";
    #description = "";
    comment = "Update System";
    exec = "sudo bash /etc/nixos/hosts/enterprise-base/switch.sh";
    icon = "teams-for-linux";
    terminal = true;
    type = "Application";
    categories = [ "System" ];
  };
}
