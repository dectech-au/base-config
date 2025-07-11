#~/.dotfiles/sys-modules/lan-mouse.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    lan-mouse
  ];
}
