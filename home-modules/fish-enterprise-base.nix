#/etc/nixos/home-modules/fish-enterprise-base.nix
{ config, lib, pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellInit = "cd ~";
    shellInitLast = "fastfetch";
    shellAbbrs = {
      "update" = "sudo bash /etc/nixos/hosts/enterprise-base/switch.sh";
      "server" = "ssh -t z-home@192.168.1.157 bash -c '\"tmux attach -t main || tmux new -s main fish\"'";
    };
  };

  home.file.".config/fish/conf.d/disable-greeting.fish".text = ''
    set -U fish_greeting ""
  '';
}
