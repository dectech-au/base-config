#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, inputs, ... }:
{
  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
    };
  };
}
