#/etc/nixos/modules/teams.nix
{ config, lib, pkgs, ... }:
{
	environment.systemPackages = with pkgs; [
		teams-for-linux
	];
}
