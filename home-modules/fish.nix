#/etc/nixos/home-modules/fish.nix
{ config, lib, pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellInit = "cd ~";
    shellInitLast = "fastfetch";
    shellAbbrs = {
      "update" = "sudo bash /etc/nixos/hosts/enterprise-base/switch.sh";
      "server" = "ssh -i ~/.ssh/id_nixos_readonly z-home@192.168.1.157";
    };
  };
}
