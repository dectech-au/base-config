#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, ... }:
{
	programs.firefox = {
    enable = true;
    profiles.default.extensions = {
      packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
      ];
      settings."uBlock@raymondhill.net".settings = {
        selectedFilterLists = [
          "ublock-filters"
          "ublock-badware"
          "ublock-privacy"
          "ublock-unbreak"
          "ublock-quick-fixes"
        ];
      };
    };
  };

}
