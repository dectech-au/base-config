#~/.dotfiles/modules/plasma.nix
{ config, lib, pkgs, ... }:
{
  services = {
    xserver.enable = true;
    displayManager = {
      sddm.enable = true; 
      autoLogin = {
        enable = false;
        user = "dectec";
      };
    };
    desktopManager.plasma6.enable = true;
  };
}
