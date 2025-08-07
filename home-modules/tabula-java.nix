#/etc/nixos/home-modules/tabula-java.nix
{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    tabula-java
  ];
}
