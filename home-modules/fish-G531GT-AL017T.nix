#/etc/nixos/home-modules/fish-G531GT-AL017T.nix
{ config, lib, pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellInit = "cd ~";
    shellInitLast = "fastfetch";
    
    shellAliases = {
      server = "ssh -t z-home@192.168.1.157 'tmux attach -t main || tmux new -s main fish'";
      update = "sudo bash /etc/nixos/hosts/G531GT-AL017T/switch.sh";
    };
  };

  home.file.".config/fish/conf.d/disable-greeting.fish".text = ''
    set -U fish_greeting ""
  '';
}
