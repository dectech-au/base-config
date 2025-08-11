#/etc/nixos/flake-parts/nix-sops.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, sops-nix, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # NixOS modules
      nixosModules = {
        sops = sops-nix.nixosModules.sops;
        sops-defaults = { config, lib, pkgs, ... }: {
          imports = [ sops-nix.nixosModules.sops ];
          
          # Default sops configuration
          sops = {
            defaultSopsFile = ./secrets.yaml;
            age.keyFile = "/var/lib/sops-nix/key.txt";
            
            # Optional: configure secrets validation
            secrets = {
              # Example: SSH host key
              "ssh_host_rsa_key" = {
                mode = "0400";
                owner = "root";
                group = "root";
              };
              
              # Example: Tailscale key
              "tailscale/hskey.txt" = {
                mode = "0400";
                owner = "root";
                group = "root";
              };
            };
          };
        };
      };

      # Home-manager modules
      homeManagerModules = {
        sops = sops-nix.homeManagerModules.sops;
      };

      # Development shell
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
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
      });

      # Packages
      packages = forAllSystems (system: {
        sops = nixpkgs.legacyPackages.${system}.sops;
        age = nixpkgs.legacyPackages.${system}.age;
      });

      # Checks
      checks = forAllSystems (system: {
        sops-check = nixpkgs.legacyPackages.${system}.runCommand "sops-check" {
          buildInputs = [ nixpkgs.legacyPackages.${system}.sops ];
        } ''
          echo "Checking sops installation..."
          sops --version
          echo "✅ Sops check passed"
          touch $out
        '';
      });

      # Documentation
      lib = {
        # Helper function to create a secrets file
        mkSecretsFile = { secrets, ageKeyFile ? "/var/lib/sops-nix/key.txt" }: {
          sops = {
            defaultSopsFile = ./secrets.yaml;
            age.keyFile = ageKeyFile;
            secrets = secrets;
          };
        };

        # Example secrets configuration
        exampleSecrets = {
          "ssh_host_rsa_key" = {
            mode = "0400";
            owner = "root";
            group = "root";
          };
          "tailscale/hskey.txt" = {
            mode = "0400";
            owner = "root";
            group = "root";
          };
          "database/password" = {
            mode = "0400";
            owner = "postgres";
            group = "postgres";
          };
        };
      };
    };
}
