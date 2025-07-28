#/etc/nixos/hosts/personal-tim/flake-part.nix
{ inputs, self, ... }:
{
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations.personal-tim = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };

    modules = [
      { nixpkgs.config.allowUnfree = true; }
      ../../sys-modules/hostname.nix
      ./configuration.nix
      inputs.nixvim.nixosModules.nixvim
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.dectec = import ./home.nix;
          sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
        };
      }
    ];
  };
}
