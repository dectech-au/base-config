#~/.dotfiles/modules/start-menu/update.nix
{ config, lib, pkgs, ... }:
{
  xdg.desktopEntries.update = {
    name = "Update";
    #description = "";
    comment = "Update System";
    exec = "sudo bash /etc/nixos/hosts/enterprise-base/switch.sh";
    icon = "update-notifier";
    terminal = true;
    type = "Application";
    categories = [ "System" ];
  };
}
