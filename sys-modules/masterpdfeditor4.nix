#/etc/nixos/sys-modules/masterpdfeditor4.nix
{ config, lib, pkgs, ... }:
{
	environment.systemPackages = with pkgs; [
		masterpdfeditor4
	];
}
