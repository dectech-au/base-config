# sys-modules/sops.nix
{ pkgs, sops-nix, ... }:
{
  imports = [ sops-nix.nixosModules.sops ];

  config = {
    
    sops = {
      #defaultSopsFile = ../secrets.yaml;

      secrets = {
        "tailscale/hskey.txt" = {
          mode = "0400";
          owner = "root";
          group = "root";
        };
      };
    };
    
    environment.systemPackages = with pkgs; [ sops age gnupg ];
  };
}
# process to set up sops
# 1. generate key-pair with age
# $ mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt
