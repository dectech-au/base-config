#~/.dotfiles/modules/thunderbird.nix
{ config, lib, pkgs, ... }:
{
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        extensions.autoDisableScopes = "0";
      };
      # extensions = [
      #
      # ];
    };
  };
}
