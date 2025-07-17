#/etc/nixos/sys-modules/nixpkgs-fmt.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nixpkgs-fmt
  ];
}
