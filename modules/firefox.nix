#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, ... }:
{
	environment.systemPackages = with pkgs; [
    nurl
  ];

  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
      ];
      settings.extensions.autoDisableScopes = 0;
    };
  };
}
