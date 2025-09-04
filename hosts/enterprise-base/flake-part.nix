#/etc/nixos/hosts/enterprise-base/flake-part.nix
{ inputs, self, ... }:
{
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations.enterprise-base = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };

    modules = [
      { nixpkgs.config.allowUnfree = true; }
      ../../sys-modules/hostname.nix
      ./configuration.nix
      inputs.nixvim.nixosModules.nixvim
      inputs.remotemouse.nixosModules.remotemouse
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "bak";
          users.dectec = import ./home.nix;
          sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
        };
      }
    ];
  };
}
