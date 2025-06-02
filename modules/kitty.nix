#/etc/nixos/modules/kitty.nix
{ config, lib, pkgs, ... }:

{
	programs.kitty = {
		enable = true;
		
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    themeFile = "./themeFile/GruvboxMaterialDarkMedium";

    shellIntegration.enableFishIntegration = true;
	};
}
