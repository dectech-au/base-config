#/etc/nixos/flake.nix
{
  description = "DecTec default flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    
    flake-parts.url = "github:hercules-ci/flake-parts";
    #flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        ./hosts/overlays.nix
        ./hosts/enterprise-base/flake-part.nix
        ./hosts/personal-tim/flake-part.nix
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        formatter = pkgs.nixpkgs-fmt;

        packages = {
          remotemouse = pkgs.callPackage ./sys-modules/remotemouse {
            glib = pkgs.glib;
            dbus = pkgs.dbus;
            zlib = pkgs.zlib;
            freetype = pkgs.freetype;
            fontconfig = pkgs.fontconfig;
            libxkbcommon = pkgs.libxkbcommon;
            libGL = pkgs.libGL;
            alsa-lib = pkgs.alsa-lib;
            xorg = pkgs.xorg;
            xdotool = pkgs.xdotool;
          };
          default = self'.packages.remotemouse;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            nixpkgs-fmt
            neovim
          ];
          shellHook = ''
            echo "Developer Mode: Engaged."
          '';
        };
      };
    };
}
