# sys-modules/sops.nix
{ inputs, config, lib, pkgs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    # Encrypted secrets live here, adjust the path to your repo layout
    defaultSopsFile = ../secrets/secrets.yaml;

    # Example secret to prove the plumbing
    secrets."example/db_password" = { };
  };
}

# process to set up sops
# 1. generate key-pair with age
# $ mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt
