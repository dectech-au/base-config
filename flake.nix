#/etc/nixos/flake.nix
{
  description = "DecTec default flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
       url = "github:nix-community/nixvim";
     inputs.nixpkgs.follows = "nixpkgs";
    };

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, nixvim, aagl, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            
            { 
              imports = [ aagl.nixosModules.default ];
              nix.settings = aagl.nixConfig;
              aagl.enableNixpkgsReleaseBranchCheck = false;
              # programs.anime-game-launcher.enable = true; # Adds launcher and /etc/hosts rules
              programs.anime-games-launcher.enable = true;      # ??
              programs.honkers-railway-launcher.enable = true;  # Honkai: Star Rail
              programs.honkers-launcher.enable = true;          # Honkai: Impact 3rd
              # programs.wavey-launcher.enable = true;            # ???
              # programs.sleepy-launcher.enable = true;           # Zenless Zone Zero
            }
            
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.dectec = import ./home.nix;
            }
	          nixvim.nixosModules.nixvim
          ];
        };
      };
    };
}

