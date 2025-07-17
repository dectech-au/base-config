#/etc/nixos/home-modules/fish.nix
{ config, lib, pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellInit = "cd ~";
    shellInitLast = "fastfetch";
    shellAbbrs = {
      "update" = "bash /etc/nixos/update-personal-tim.sh";
    };
  };
}
