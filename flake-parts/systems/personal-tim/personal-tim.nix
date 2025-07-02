#~/.dotfiles/flake-parts/systems/personal-tim.nix
{ inputs, ... }:
{
  flake.nixosConfigurations.personal-tim = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };

    modules = [
      { nixpkgs.config.allowUnfree = true; }
      ../../../hosts/personal-tim/configuration.nix
      ../../../flake-modules/autoupdate-personal-tim.nix
      inputs.nixvim.nixosModules.nixvim
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.dectec = import ../../../hosts/personal-tim/home.nix;
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
}
