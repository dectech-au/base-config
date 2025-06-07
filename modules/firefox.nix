#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, inputs, ... }:

{
  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
        ublock-origin
      ];
    };
  };

  programs.librewolf = {
    enable = true;
  };
}
