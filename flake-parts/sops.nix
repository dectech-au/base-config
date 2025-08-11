# nix-sops.nix
{ inputs, ... }:

# Everything lives in THIS file; no more scattering.
{
  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

  ##################################################
  # 1.  Build the packages and publish an overlay
  ##################################################
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
      inherit overlay;          # flake-parts hoists this to self.overlays.default
      
      # Development shell with sops tools
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

  ##################################################
  # 2.  NixOS module that wires it up
  ##################################################
  nixosModules.sops = { lib, pkgs, ... }: {
    config = {
      # Pull in the overlay we just exported
      nixpkgs.overlays = [
        inputs.self.overlays.default
      ];

      # Import the sops-nix NixOS module
      imports = [ inputs.sops-nix.nixosModules.sops ];

      # Default sops configuration
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile = "/var/lib/sops-nix/key.txt";
        
        # Configure secrets with proper permissions
        secrets = {
          # SSH host key example
          "ssh_host_rsa_key" = {
            mode = "0400";
            owner = "root";
            group = "root";
          };
          
          # Tailscale key example
          "tailscale/hskey.txt" = {
            mode = "0400";
            owner = "root";
            group = "root";
          };
          
          # Database password example
          "database/password" = {
            mode = "0400";
            owner = "postgres";
            group = "postgres";
          };
        };
      };

      # Install sops tools in system packages
      environment.systemPackages = with pkgs; [
        sops
        age
        gnupg
      ];

      # Create the sops-nix directory
      systemd.tmpfiles.rules = [
        "d /var/lib/sops-nix 0700 root root"
      ];
    };
  };

  ##################################################
  # 3.  Home-manager module for user-level secrets
  ##################################################
  homeManagerModules.sops = { lib, pkgs, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];
    
    config = {
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile = "~/.config/sops/age/keys.txt";
      };
    };
  };
}
