#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, inputs, ... }:
{
  programs.firefox = {
    enable = true;
  };

  programs.librewolf = {
    enable = true;
  };
}
