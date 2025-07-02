#~/.dotfiles/flake-parts/systems/personal-tim/base.nix
{ inputs, ... }:
{
  imports = [
    ./system.nix
    ./home.nix
    ./aagl.nix
  ];

  flake.nixosConfigurations.personal-tim = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./personal-tim/config.nix
    ];
  };
}
