#~/.dotfiles/flake.nix
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
      lib = nixpkgs.lib; 
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      overlays = [
        (final: prev: {
          firefox-addons = inputs.firefox-addons.packages.${system};
         })
      ];
    in {
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            
            { 
              imports = [ aagl.nixosModules.default ];
              nix.settings = aagl.nixConfig;
              aagl.enableNixpkgsReleaseBranchCheck = false;
              # programs.anime-games-launcher.enable = true;    # Hoyo Launcher
              programs.honkers-railway-launcher.enable = true;  # Honkai: Star Rail
              programs.honkers-launcher.enable = true;          # Honkai: Impact 3rd
              # programs.sleepy-launcher.enable = true;         # Zenless Zone Zero
            }
            
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.dectec = import ./home.nix;
            }
	          nixvim.nixosModules.nixvim
          ];
          specialArgs = {
            inherit inputs;
          };
          pkgs = import nixpkgs {
            inherit system overlays;
          };
        };
      };
    };
}

