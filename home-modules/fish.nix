#/etc/nixos/modules/fish.nix
{ config, lib, pkgs, ... }:

{
	programs.fish = {
    enable = true;
    shellInit = "cd ~/.dotfiles/";
    shellInitLast = "fastfetch";
  };
}
