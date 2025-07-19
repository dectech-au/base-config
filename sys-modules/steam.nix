#~/.dotfiles/modules/steam.nix
{ config, lib, pkgs, ... }:
{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    protonup-ng
    protonup-qt
  ];
}
