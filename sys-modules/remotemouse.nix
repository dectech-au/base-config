# sys-modules/remotemouse.nix
{ pkgs, ... }:
{
  config = {
    environment.systemPackages = [ pkgs.xhost ];
    nixpkgs.config.allowUnfree = true;
    networking.firewall.allowedTCPPorts = [ 1978 6666 ];
    networking.firewall.allowedUDPPorts = [ 1978 6666 ];
  };
}
