#/etc/nixos/sys-modules/age.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    age
  ];
}
