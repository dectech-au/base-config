#~/.dotfiles/flake-parts/systems/personal-tim/base.nix
{ inputs, ... }:
{
  imports = [
    ./system.nix
    ./home.nix
    ./aagl.nix
  ];
}
