#~/.dotfiles/flake-parts/systems/personal-tim/system.nix
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
    ];
  };
}
