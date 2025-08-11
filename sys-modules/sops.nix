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
# 1. Generate age-key for admins
# age-keygen -o ~/.config/sops/age/keys.txt
# 2. create in the repo root ".sops.yaml" which contains the creation rules in the following format:
# creation_rules:
#    - path_regex: ^secrets/.*\.yaml$
#      age:
#        - age1<string>
#
# 3. generate the target machines public ssh key:
# sudo ssh-keygen -A
#
# 4. Use ssh-to-age to generate the key
# ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
#
# 5. 
