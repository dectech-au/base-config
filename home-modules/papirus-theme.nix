#/etc/nixos/home-modules/papirus-theme.nix
{ config, lib, pkgs, ... }:
{
  xdg.configFile."kdeglobals".text = ''
    [Icons]
    Theme=Papirus
  '';
}
