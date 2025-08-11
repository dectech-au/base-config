# sys-modules/sops.nix
{ inputs, config, lib, pkgs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    secrets."headscale/server_key" = { };        # 
  };

  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}

####################################
# SETTING UP SOPS
####################################
# 1. Generate age-key for admins
#       age-keygen -o ~/.config/sops/age/keys.txt
#
# 2. create in the repo root ".sops.yaml" which contains the creation rules in the following format:
# creation_rules:
#    - path_regex: ^secrets/.*\.yaml$
#      age:
#        - age1<string>
#
# 3. generate the target machines public ssh key:
#       sudo ssh-keygen -A
#
# 4. Use ssh-to-age to generate the key
#       ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
#
# 5.
#
#
#
#
# ?. Access sops by entering the repo root, and run:
# sops s
#
# ?. reference the secret in the relevant module
# password = config.sops.secrets."secretheading/secretname".path;
#
# ?. add the name of the secret to sys-modules/sops.nix
