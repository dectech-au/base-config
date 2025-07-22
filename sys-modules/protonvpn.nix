#/etc/nixos/sys-modules/protonvpn.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    protonvpn-cli_2
  ];
}
