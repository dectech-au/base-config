#~/.dotfiles/modules/kcalc.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
  ];
}
