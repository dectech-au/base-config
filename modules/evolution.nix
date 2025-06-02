#/etc/nixos/modules/evolution.nix
{ config, lib, pkgs, ... }:
{
	programs.evolution = {
		enable = true;
	};
}
