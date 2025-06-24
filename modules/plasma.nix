#~/.dotfiles/modules/plasma.nix
{ config, lib, pkgs, ... }:
{
  services = {
    xserver.enable = true;
    displayManager.sddm = {
      enable = true;
      #defaultSession = "plasma.desktop";
    };
    desktopManager.plasma6.enable = true;
  };
}
