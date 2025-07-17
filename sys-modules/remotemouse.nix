#/etc/nixos/sys-modules/remotemouse.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    inputs.self.nixosModules.remotemouse
  ];

  networking.firewall = {
    allowedTCPPorts = [ 1978 ];
    allowedUDPPorts = [ 1978 ];
  };
}
