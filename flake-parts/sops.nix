# flake-parts/sops.nix
{ inputs, ... }:
{
  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

  perSystem = { pkgs, system, ... }:
    let
      sops = pkgs.sops;
      age = pkgs.age;
      gnupg = pkgs.gnupg;
      
      overlay = final: prev: { 
        inherit sops age gnupg;
      };
    in {
      packages = {
        inherit sops age gnupg;
        default = sops;
      };
      inherit overlay;
      
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
}
