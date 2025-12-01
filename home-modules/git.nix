#/etc/nixos/modules/git.nix
{ config, lib, pkgs, ... }:
{
	programs.git = {
		enable = true;
		settings.user = {
			name = "DecTec";
			email = "zozano@protonmail.com";
		};
	};
}
