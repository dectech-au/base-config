#/etc/nixos/modules/gparted.nix
{ config, lib, pkgs, ... }:
{
	environment.systemPackages = with pkgs; [
		gparted
	];
}
