#/etc/nixos/flake-parts/system/personal-tim/personal-tim.nix
{ inputs, self, ... }:
{
  systems = [ "x86_64-linux ];

  flake.nixosConfigurations.personal-tim = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };

    modules = [
      { nixpkgs.config.allowUnfree = true; }
      ../../../hosts/personal-tim/configuration.nix
      inputs.nixvim.nixosModules.nixvim
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.dectec = import ../../../hosts/personal-tim/home.nix;
        };
      }
    ] ++ (
      if builtins.pathExists ../../../hosts/hostname.nix
      then [ ../../../hosts/hostname.nix ]
      else [ ] );
  };
}
