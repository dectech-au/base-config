#/etc/nixos/home-modules/papirus-theme.nix
{ config, lib, pkgs, ... }:
{
  environment.variables = {
    QT_STYLE_OVERRIDE = "papirus";
  };
}
