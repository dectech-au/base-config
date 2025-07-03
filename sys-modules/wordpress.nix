#~/.dotfiles/sys-modules/wordpress.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wordpress
  ];
}
