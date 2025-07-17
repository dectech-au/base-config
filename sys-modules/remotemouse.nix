#/etc/nixos/sys-modules/remotemouse.nix
{ config, lib, pkgs, ... }:

let
  rmPkg = pkgs.callPackage ../remotemouse { xdotool = pkgs.xdotool; };
in {
  environment.systemPackages = [
    rmPkg
    pkgs.xorg.xhost  # handy for X auth troubleshooting
  ];
  nixpkgs.config.allowUnfree = true;
  networking.firewall.allowedTCPPorts = [ 1978 ];
  networking.firewall.allowedUDPPorts = [ 1978 ];
}
