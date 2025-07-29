#/etc/nixos/home-modules/fish-enterprise-base.nix
{ config, lib, pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellInit = "cd ~";
    shellInitLast = "fastfetch";
    shellAbbrs = {
      "update" = "sudo bash /etc/nixos/hosts/enterprise-base/switch.sh";
    };
  };
}
