# sys-modules/remotemouse.nix
{ pkgs, ... }:
let
  remotemouse = pkgs.callPackage ../../flake-parts/pkg/remote-mouse.nix { xdotool = pkgs.xdotool; };
in {
  config = {
    nixpkgs.overlays = [ (final: prev: { inherit remotemouse; }) ];
    environment.systemPackages = [ remotemouse pkgs.xorg.xhost ];
    nixpkgs.config.allowUnfree = true;
    networking.firewall.allowedTCPPorts = [ 1978 ];
    networking.firewall.allowedUDPPorts = [ 1978 ];
  };
}
