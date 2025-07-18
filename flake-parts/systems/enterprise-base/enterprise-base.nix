#~/.dotfiles/flake-parts/systems/enterprise-base.nix
{ inputs, ... }:
{
  flake.nixosConfigurations.enterprise-base = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };

    modules = [
      { nixpkgs.config.allowUnfree = true; }
      ../../../hosts/enterprise-base/configuration.nix
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.dectec = import ../../../hosts/enterprise-base/home.nix;
        };
      }
      inputs.nixvim.nixosModules.nixvim
    ];
  };
}

