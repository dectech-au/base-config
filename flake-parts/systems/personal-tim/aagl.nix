#~/.dotfiles/flake-parts/systems/personal-tim/aagl.nix
{ inputs, ... }:
{
  config.flake.nixosConfigurations.personal-tim = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };

    modules = [
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
