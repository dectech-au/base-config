#~/.dotfiles/flake.nix
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

    aagl.url = "github:ezKEa/aagl-gtk-on-nix/release-25.05";
    aagl.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];

    perSystem = { config, self', inputs', system, lib, pkgs, ... }: {
      _module.args.pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            firefox-addons = inputs.firefox-addons.packages.${system};
          })
        ];
        config.allowUnfree = true;
      };
    };

    flake.nixosConfigurations = {
      
      enterprise-base = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.config.allowUnfree = true; }
          ./hosts/enterprise-base/configuration.nix
          ./flake-modules/autoupdate-enterprise-base.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtensions = "backup";
              users.dectec = import ./hosts/enterprise-base/home.nix;
            };
          }
          inputs.nixvim.nixosModules.nixvim
        ];
      };

      personal-tim = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.config.allowUnfree = true; }
          ./hosts/personal-tim/configuration.nix
          ./flake-modules/autoupdate-personal-tim.nix
          inputs.nixvim.nixosModules.nixvim
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              users.dectec = import ./hosts/personal-tim/home.nix;
            };
          }
          {
            imports = [ inputs.aagl.nixosModules.default ];
            nix.settings = inputs.aagl.nixConfig;
            aagl.enableNixpkgsReleaseBranchCheck = false;
            programs.honkers-railway-launcher.enable = true;
            programs.honkers-launcher.enable = true;
          }
        ];
      };
    };
  };
}
