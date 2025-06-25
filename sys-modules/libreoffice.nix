#~/.dotfiles/modules/libreoffice.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libreoffice
  ];
}
