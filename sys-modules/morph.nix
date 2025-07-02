#~/.dotfiles/sys-modules/morph.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    morph
  ];
}
