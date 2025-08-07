#/etc/nixos/custom-modules/hastings-preschool/0-imports
{ config, lib, pkgs, ... }:
{
  imports = [
    ./right-click-menu.nix
    ./text2ods.nix
    ./okular2csv.nix
  ];
}
