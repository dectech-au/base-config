#~/.dotfiles/modules/librewolf.nix
{ config, lib, pkgs, ... }:
{
  programs.librewolf = {
    enable = true;
  };
}
