#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, inputs, ... }:

let
  firefox-addons = pkgs.callPackage <nixpkgs/pkgs/applications/networking/browsers/firefox/extensions.nix> {};
in {
  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions = with pkgs; [
        nur.repos.rycee.firefox-addons.ublock-origin
      ];
    };
  };

  programs.librewolf = {
    enable = true;
  };
}
