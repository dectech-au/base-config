#/etc/nixos/sys-modules/fonts.nix
{ config, lib, pkgs, ... }:
{
	fonts.packages = with pkgs; [
		corefonts
		vistafonts-chs
		dejavu_fonts
		cantarell-fonts
	];
	fonts.enableDefaultPackages = true;
	fonts.fontDir.enable = true;
}
