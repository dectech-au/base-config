#/etc/nixos/sys-modules/protonvpn.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    protonvpn-gui
  ];
}
