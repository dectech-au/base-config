#/etc/nixos/sys-modules/remotemouse.nix
{ config, lib, pkgs, inputs, ... }:

let
  rmPkg = pkgs.callPackage ../remotemouse { xdotool = pkgs.xdotool; };
in {
  environment.systemPackages = [
    rmPkg
    pkgs.xorg.xhost  # handy for X auth troubleshooting
  ];

  networking.firewall.allowedTCPPorts = [ 1978 ];
  networking.firewall.allowedUDPPorts = [ 1978 ];
}
