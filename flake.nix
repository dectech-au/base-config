#/etc/nixos/flake.nix
{
  description = "DecTec default flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    
    flake-parts.url = "github:hercules-ci/flake-parts";
    #flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    remotemouse = {
      url = "github:dectech-au/remotemouse";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-sops.url = "path:./flake-parts/nix-sops.nix";
    nix-sops.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        ./flake-parts/nix-sops.nix
        ./hosts/overlays.nix
        ./hosts/enterprise-base/flake-part.nix
        ./hosts/enterprise-base-ssd/flake-part.nix
        ./hosts/personal-tim/flake-part.nix
        ./hosts/G531GT-AL017T/flake-part.nix
        #./sys-modules/remotemouse-flakepart.nix
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        formatter = pkgs.nixpkgs-fmt;

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
