#~/.dotfiles/sys-modules/baobab.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    baobab
  ];
}
