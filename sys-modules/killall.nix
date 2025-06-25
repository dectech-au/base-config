#~/.dotfiles/modules/killall.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    killall
  ];
}
