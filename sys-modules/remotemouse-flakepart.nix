{ inputs, ... }:

# Everything lives in THIS file; no more scattering.
{
  systems = [ "x86_64-linux" ];

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
      inherit overlay;          # flake-parts hoists this to self.overlays.default
    };

  ##################################################
  # 2.  NixOS module that wires it up
  ##################################################
  nixosModules.remotemouse = { lib, pkgs, ... }: {
    config = {
      # Pull in the overlay we just exported
      nixpkgs.overlays = [
        inputs.self.overlays.default
      ];

      environment.systemPackages = [
        pkgs.remotemouse
        pkgs.xorg.xhost
      ];

      networking.firewall.allowedTCPPorts = [ 1978 ];
      networking.firewall.allowedUDPPorts = [ 1978 ];

      nixpkgs.config.allowUnfree = true;
    };
  };
}
