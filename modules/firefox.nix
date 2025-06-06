#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions = with pkgs; [
        firefox-addons.ublock-origin
      ];  
    #   extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
    #     ublock-origin
    #   ];
    #   settings.extensions.autoDisableScopes = 0;
    };
  };
}
