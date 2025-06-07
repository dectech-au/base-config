#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, inputs, ... }:

{
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      name = "Default";
      settings = {
        # settings go here
      };
      extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
        ublock-origin
      ];
    };
  };

  programs.librewolf = {
    enable = true;
  };
}
