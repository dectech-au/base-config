#/etc/nixos/sys-modules/remotemouse.nix
{ config, lib, pkgs, ... }:
{
  networking.firewall = {
    allowedTCPPorts = [ 1978 ];
    allowedUDPPorts = [ 1978 ];
  };
}
