#/etc/nixos/sys-modules/fonts.nix
{ config, lib, pkgs, ... }:
{
	fonts.packages = with pkgs; [
		corefonts
		cantarell-fonts
	];
}
