#~/.dotfiles/flake-parts/systems/personal-tim/base.nix
{ inputs, ... }:
{
  imports = [
    ./systems.nix
    ./home.nix
    ./aagl.nix
  ];
}
