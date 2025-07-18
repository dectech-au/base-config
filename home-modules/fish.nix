#/etc/nixos/home-modules/fish.nix
{ config, lib, pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellInit = "cd ~";
    shellInitLast = "fastfetch";
    shellAbbrs = {
      "update" = "bash /etc/nixos/hosts/personal-tim/switch.sh";
      "server" = "ssh -i ~/.ssh/id_nixos_readonly z-home@192.168.1.157";
    };
  };
}
