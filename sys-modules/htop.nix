#~/.dotfiles/sys-modules/htop.nix
{ config, lib, pkgs, ... }:
{
  programs.htop.enable = true;
  programs.btop.enable = true;
}
