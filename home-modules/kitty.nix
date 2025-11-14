#/etc/nixos/home-modules/kitty.nix
{ config, lib, pkgs, ... }:

{
	programs.kitty = {
		enable = true;
		
    font = {
      name = "JetBrains Mono";
      size = 11;
    };

    #themeFile = "GruvboxMaterialDarkMedium";
	#themeFile = "GruvboxMaterialMedium";
	themeFile = "SolarizedLight";

    shellIntegration.enableFishIntegration = true;
    settings.shell = "fish";
	};

  home.packages = with pkgs; [
    jetbrains-mono
  ];
}
