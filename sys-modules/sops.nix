# sys-modules/sops.nix
{ pkgs, ... }:
{
  config = {
    nixpkgs.overlays = [ (final: prev: { 
      inherit (pkgs) sops age gnupg; 
    }) ];
    
    imports = [ inputs.sops-nix.nixosModules.sops ];
    
    sops = {
      defaultSopsFile = ../../secrets.yaml;
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
