#/etc/nixos/custom-modules/hastings-preschool/weekly-schedule.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    tabula-java
  ];
}
