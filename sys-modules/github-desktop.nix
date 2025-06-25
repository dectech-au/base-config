#~/.dotfiles/modules/github-desktop.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    github-desktop
    git-lfs
  ];
}
