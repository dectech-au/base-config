# flake-parts/remotemouse.nix
{ inputs, ... }:
{
  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  
  perSystem = { pkgs, system, ... }:
    let
      remotemouse = pkgs.callPackage ./pkg/remote-mouse.nix { xdotool = pkgs.xdotool; };
      overlay = final: prev: { remotemouse = remotemouse; };
    in {
      packages = { inherit remotemouse; default = remotemouse; };
      inherit overlay;
    };

  nixosModules.remotemouse = { lib, pkgs, ... }: {
    config = {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
      environment.systemPackages = [ pkgs.remotemouse pkgs.xorg.xhost ];
      nixpkgs.config.allowUnfree = true;
      networking.firewall.allowedTCPPorts = [ 1978 ];
      networking.firewall.allowedUDPPorts = [ 1978 ];
    };
  };
}
