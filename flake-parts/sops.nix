# flake-parts/sops.nix
{ inputs, ... }:
{
  systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

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
      
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          sops
          age
          gnupg
        ];
        
        shellHook = ''
          echo "🔐 Nix-sops development environment loaded"
          echo "Available tools: sops, age, gpg"
          echo ""
          echo "To create a new age key:"
          echo "  age-keygen -o key.txt"
          echo ""
          echo "To encrypt a file:"
          echo "  sops -e -i secrets.yaml"
        '';
      };
    };

  overlays.default = final: prev: {
    inherit (inputs.self.packages.${prev.system}) sops age gnupg;
  };
}
