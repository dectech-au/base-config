# sys-modules/sops.nix
{ pkgs, sops-nix, ... }:
{
  config = {
    imports = [ sops-nix.nixosModules.sops ];
    
    sops = {
      defaultSopsFile = ../../../secrets.yaml;  # Fixed path
      age.keyFile = "/var/lib/sops-nix/key.txt";
      
      secrets = {
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
    
    environment.systemPackages = with pkgs; [ sops age gnupg ];
    systemd.tmpfiles.rules = [ "d /var/lib/sops-nix 0700 root root" ];
  };
}
