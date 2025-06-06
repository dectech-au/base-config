#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, ... }:
{
	programs.firefox = {
    enable = true;
    profiles.default.extensions.packages = with pkgs.firefox-addons; [
      ublock-origin
    ];
  };
}
