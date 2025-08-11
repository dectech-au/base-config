# flake-parts/remotemouse.nix
{ inputs, ... }:

{
  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

  ##################################################
  # 1.  Build the package and publish an overlay
  ##################################################
  perSystem = { pkgs, system, ... }:
    let
      remotemouse =
        pkgs.callPackage ./pkg/remote-mouse.nix {
          xdotool = pkgs.xdotool;
        };

      overlay = final: prev: { remotemouse = remotemouse; };
    in {
      packages = {
        inherit remotemouse;
        default = remotemouse;
      };
      inherit overlay;
    };

  ##################################################
  # 2.  NixOS module that wires it up (merged config)
  ##################################################
  nixosModules.remotemouse = { lib, pkgs, ... }: {
    config = {
      # Pull in the overlay we just exported
      nixpkgs.overlays = [
        inputs.self.overlays.default
      ];

      # All the configuration from your sys-modules/remotemouse.nix
      environment.systemPackages = [
        pkgs.remotemouse
        pkgs.xorg.xhost  # handy for X auth troubleshooting
      ];
      
      nixpkgs.config.allowUnfree = true;
      
      networking.firewall.allowedTCPPorts = [ 1978 ];
      networking.firewall.allowedUDPPorts = [ 1978 ];
    };
  };
}
