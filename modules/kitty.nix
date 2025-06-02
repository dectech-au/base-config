#/etc/nixos/modules/kitty.nix
{ config, lib, pkgs, ... }:

{
	programs.kitty = {
		enable = true;
		
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    theme = "Gruvbox Dark";

    shellIntegration.enableFishIntegration = true;
	};

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "JetbrainsMono"]; })
  ];

}
