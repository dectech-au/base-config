# flake-parts/sops.nix
{ inputs, ... }:
{
  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

  perSystem = { pkgs, system, ... }:
    let
      sops = pkgs.sops;
      age = pkgs.age;
      gnupg = pkgs.gnupg;
    in {
      packages = {
        inherit sops age gnupg;
        default = sops;
      };
    };
}
