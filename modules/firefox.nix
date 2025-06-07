#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, inputs, ... }:

  let
    addons = with pkgs.firefox-addons; [
      ublock-origin
    ];
  in
  
{
  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions = {
        packages = addons;
      };
    };
  };

  programs.librewolf = {
    enable = true;
  };
}
