{ config, lib, pkgs, ... }:
{
  virtualisation.docker.enable = true;

  networking.firewall = {
    allowedTCPPorts = [ 26099 ];
    allowedUDPPorts = [ 26099 ];
  };
}
