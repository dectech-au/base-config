#~/.dotmodules/modules/wine.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    wineWowPackages.waylandFull
  ];
}
