#~/.dotfiles/modules/signal-desktop.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    signal-desktop
  ];
}
