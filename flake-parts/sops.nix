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

  flakeModules.sops = { lib, pkgs, ... }: {
    config = {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
      imports = [ inputs.sops-nix.nixosModules.sops ];
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile = "/var/lib/sops-nix/key.txt";
        secrets = {
          "ssh_host_rsa_key" = { mode = "0400"; owner = "root"; group = "root"; };
          "tailscale/hskey.txt" = { mode = "0400"; owner = "root"; group = "root"; };
          "database/password" = { mode = "0400"; owner = "postgres"; group = "postgres"; };
        };
      };
      environment.systemPackages = with pkgs; [ sops age gnupg ];
      systemd.tmpfiles.rules = [ "d /var/lib/sops-nix 0700 root root" ];
    };
  };
}
