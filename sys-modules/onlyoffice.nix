#/etc/nixos/sys-modules/onlyoffice.nix
{ config, lib, pkgs, ... }:

{
	environment.systemPackages = with pkgs; [
		onlyoffice-bin
	];

	nixpkgs.config.allowUnfreePredicate = pkg:
		builtins.elem (lib.getName pkg) [ "corefonts" "cantarell-fonts" ];

	fonts.packages = with pkgs; [
		corefonts
		cantarell-fonts
	];
}
