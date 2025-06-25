#/etc/nixos/modules/fonts.nix
{ config, lib, pkgs, ... }:
{
	fonts.fonts = with pkgs; [
		corefonts
    cantarell-fonts
	];
}
