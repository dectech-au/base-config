# sys-modules/sops.nix
{ pkgs, sops-nix, ... }:
let
  ageKeyFile = pkgs.writeText "age-key" (builtins.readFile /var/lib/sops-nix/key.txt);
in
{
  imports = [ sops-nix.nixosModules.sops ];

  config = {
    
    sops = {
      defaultSopsFile = ../secrets.yaml;
      #age.keyFile = ageKeyFile;

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
