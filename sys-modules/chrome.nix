#/etc/nixos/modules/chrome.nix
{ config, lib, pkgs, ... }:
{
	environment.systemPackages = with pkgs; [
		google-chrome
		chromium
	];
}
