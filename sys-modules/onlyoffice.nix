#/etc/nixos/sys-modules/onlyoffice.nix
{ config, lib, pkgs, ... }:
let
  onlyofficeEnv = pkgs.buildFHSEnv {
    name       = "onlyoffice";
    targetPkgs = pkgs: with pkgs; [
      onlyoffice-bin
      cantarell-fonts
    ];
    runScript  = "desktopeditors";
  };
in
{
  environment.systemPackages = [ onlyofficeEnv ];
}	



#	environment.systemPackages = with pkgs; [
#		onlyoffice-bin
#	];

#	nixpkgs.config.allowUnfreePredicate = pkg:
#		builtins.elem (lib.getName pkg)
#		[
#			"corefonts"
#			"cantarell-fonts"
#		];

#	fonts = {
		
#		enableDefaultPackages = true;
#		enableGhostscriptFonts = true;

#		packages = with pkgs; [
#			corefonts
#			vista-fonts
#			liberation_ttf
#			cantarell-fonts
#			dejavu_fonts
#			noto-fonts
#			fira-code
#			jetbrains-mono
#		];
#	};
#}
