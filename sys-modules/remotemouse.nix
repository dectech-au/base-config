{ config, lib, pkgs, ... }:

let
  rmPkg = pkgs.callPackage ../remotemouse { xdotool = pkgs.xdotool; };
in
{
  environment.systemPackages = [ rmPkg ];

  networking.firewall.allowedTCPPorts = [ 1978 ];
  networking.firewall.allowedUDPPorts = [ 1978 ];

nixpkgs.config.allowUnfree = true;
}
