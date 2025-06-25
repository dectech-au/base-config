#~/.dotfiles/modules/birdtray.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    birdtray
  ];
}
