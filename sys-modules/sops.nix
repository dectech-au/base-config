# sys-modules/sops.nix
{ pkgs, sops-nix, ... }:
{
  imports = [ sops-nix.nixosModules.sops ];

  config = {
    
    sops = {
      defaultSopsFile = ../secrets.yaml;
      age.keyFile = "/var/lib/sops-nix/key.txt";
      
      secrets = {
        "tailscale/hskey.txt" = {
          mode = "0400";
          owner = "root";
          group = "root";
        };
      };
    };
    
    environment.systemPackages = with pkgs; [ sops age gnupg ];
    systemd.tmpfiles.rules = [ "d /var/lib/sops-nix 0700 root root" ];
  };
}
