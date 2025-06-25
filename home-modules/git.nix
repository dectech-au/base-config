#/etc/nixos/modules/git.nix
{ config, lib, pkgs, ... }:
{
	programs.git = {
		enable = true;
		userName = "DecTec";
		userEmail = "zozano@protonmail.com";
	};
}
