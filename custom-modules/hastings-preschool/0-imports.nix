#/etc/nixos/custom-modules/hastings-preschool/0-imports
{ config, lib, pkgs, ... }:
{
  imports = [
    ./right-click-menu.nix
    ./text2ods.nix
    ./oular2csv.nix
  ];
}
