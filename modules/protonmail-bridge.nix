#~/.dotfiles/modules/protonmail-bridge.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    protonmail-bridge-gui
  ];
}
