# sys-modules/remotemouse.nix
{ pkgs, ... }:
{
  config = {
    environment.systemPackages = [ pkgs.xorg.xhost ];
    nixpkgs.config.allowUnfree = true;
    networking.firewall.allowedTCPPorts = [ 1978 ];
    networking.firewall.allowedUDPPorts = [ 1978 ];
  };
}
