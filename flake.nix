#~/.dotfiles/flake.nix
{
  description = "DecTec default flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    flake-parts.url = "github:hercules-ci/flake-parts";
    #flake-parts.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    aagl.url = "github:ezKEa/aagl-gtk-on-nix/release-25.05";
    aagl.inputs.nixpkgs.follows = "nixpkgs";

    #firefox-addons.url = "github:nix-community/nur";
  };

  outputs = inputs@{ self, flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];
    imports = [
      ./flake-parts/overlays.nix
      ./flake-parts/systems/enterprise-base/enterprise-base.nix
      ./flake-parts/systems/personal-tim/personal-tim.nix
    ];
  };
}
