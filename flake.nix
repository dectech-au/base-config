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
        
        enterprise-base = lib.nixosSystem {
          inherit system;
          specialArgs = { 
            MODULES = { 
              bluetooth = ./modules/bluetooth.nix;
              btrfs = ./modules/btrfs.nix;
              chrome = ./modules/chrome.nix;
              dropbox = ./modules/dropbox.nix;
              evolution = ./modules/evolution.nix;
              fish = ./modules/fish.nix;
              firefox = ./modules/firefox.nix;
              git = ./modules/git.nix;
              gparted = ./modules/gparted.nix;
              kitty = ./modules/kitty.nix;
              librewolf = ./modules/librewolf.nix;
              nixvim = ./modules/nixvim.nix;
              onlyoffice = ./modules/onlyoffice.nix;
              papirus = ./modules/papirus.nix;
              teams = ./modules/teams.nix;
              wine = ./modules/wine.nix;

              start-menu_onlyoffice = ./modules/start-menu/start-onlyoffice.nix;
              start-menu_teams = ./modules/start-menu/start-teams.nix;
            };
          };
          modules = [
            { nixpkgs.config.allowUnfree = true; }
            ./hosts/enterprise-base/configuration.nix
            
            home-manager.nixosModules.home-manager {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.dectec = import ./hosts/enterprise-base/home.nix;
              };
            }

            nixvim.nixosModules.nixvim
          ];
        };

        personal-tim = lib.nixosSystem {
          inherit system;
          specialArgs = { 
            MODULES = {
              bluetooth = ./modules/bluetooth.nix;
              btrfs = ./modules/btrfs.nix;
              chrome = ./modules/chrome.nix;
              dropbox = ./modules/dropbox.nix;
              evolution = ./modules/evolution.nix;
              fish = ./modules/fish.nix;
              firefox = ./modules/firefox.nix;
              git = ./modules/git.nix;
              gparted = ./modules/gparted.nix;
              kitty = ./modules/kitty.nix;
              librewolf = ./modules/librewolf.nix;
              nixvim = ./modules/nixvim.nix;
              onlyoffice = ./modules/onlyoffice.nix;
              papirus = ./modules/papirus.nix;
              teams = ./modules/teams.nix;
              wine = ./modules/wine.nix;

              start-menu_onlyoffice = ./modules/start-menu/start-onlyoffice.nix;
              start-menu_teams = ./modules/start-menu/start-teams.nix;
            };
          };


          modules = [
            { nixpkgs.config.allowUnfree = true; }
            ./hosts/personal-tim/configuration.nix

            nixvim.nixosModules.nixvim

            home-manager.nixosModules.home-manager {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.dectec = import ./hosts/personal-tim/home.nix;
              };
            }

            { 
              imports = [ aagl.nixosModules.default ];
              nix.settings = aagl.nixConfig;
              aagl.enableNixpkgsReleaseBranchCheck = false;
              # programs.anime-games-launcher.enable = true;    # Hoyo Launcher
              programs.honkers-railway-launcher.enable = true;  # Honkai: Star Rail
              programs.honkers-launcher.enable = true;          # Honkai: Impact 3rd
              # programs.sleepy-launcher.enable = true;         # Zenless Zone Zero
            }
          ];
        };

        nixos = lib.nixosSystem {
          inherit system;
          specialArgs = { MODULES = ./modules; };
          modules = [
            ./configuration.nix
            { nixpkgs.config.allowUnfree = true; }
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
        };
      };
    };
}

