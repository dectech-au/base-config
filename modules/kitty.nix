#/etc/nixos/modules/kitty.nix
{ config, lib, pkgs, ... }:

{
	programs.kitty = {
		enable = true;
		
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    themeFile = "https://github.com/kovidgoyal/kitty-themes/blob/master/themes/GruvboxMaterialDarkMedium.conf";

    shellIntegration.enableFishIntegration = true;
	};

}
