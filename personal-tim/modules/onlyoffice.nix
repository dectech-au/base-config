#/etc/nixos/modules/onlyoffice.nix
{ config, lib, pkgs, ... }:

{
	# services.onlyoffice.enable = true;
	environment.systemPackages = with pkgs; [
		onlyoffice-bin
	];
}
