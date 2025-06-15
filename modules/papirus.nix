#~/.dotfiles/modules/papirus.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    papirus-icon-theme
  ];
}
