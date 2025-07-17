# /etc/nixos/sys-modules/remotemouse.nix
{ config, lib, pkgs, inputs, ... }:
let
  rmPkg =
    if inputs ? self
    then inputs.self.packages.${pkgs.system}.remotemouse
    else pkgs.callPackage ../remotemouse { xdotool = pkgs.xdotool; };
in
{
  environment.systemPackages = [ rmPkg ];

  networking.firewall.allowedTCPPorts = [ 1978 ];
  networking.firewall.allowedUDPPorts = [ 1978 ];
}
