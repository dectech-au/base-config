#~/.dotfiles/flake-parts/systems/personal-tim/home.nix
{ inputs, ... }:
{
  config.flake.nixosConfigurations.personal-tim = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };

    modules = [
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.dectec = import ../../../hosts/personal-tim/home.nix;
        };
      }
    ];
  };
}
