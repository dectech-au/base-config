#/etc/nixos/modules/fish.nix
{ config, lib, pkgs, ... }:

{
	programs.fish = {
    enable = true;
    shellInit = "cd ~/.dotfiles/";
    shellInitLast = "fastfetch";
    shellAbbrs = {
      "update" = "bash ~/.dotfiles/update-personal-tim.sh";
    };
  };
}
