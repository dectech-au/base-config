#/etc/nixos/modules/neovim.nix
{ config, lib, pkgs, ... }:
{
	programs.neovim.enable = true;
	# environment.systemPackages = with pkgs; [
	# 	neovim
	# ];
}
