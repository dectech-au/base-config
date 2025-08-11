# flake-parts/remotemouse.nix
{ inputs, ... }:
{
  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  
  perSystem = { pkgs, system, ... }:
    let
      remotemouse = pkgs.callPackage ./pkg/remote-mouse.nix { xdotool = pkgs.xdotool; };
    in {
      packages = { inherit remotemouse; default = remotemouse; };
    };

  overlays.default = final: prev: {
    remotemouse = inputs.self.packages.${prev.system}.remotemouse;
  };
}
