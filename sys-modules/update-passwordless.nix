{ config, lib, pkgs, ... }:
{
  security.sudo.extraRules = [{
    users = [ "dectec" ];
    commands = [{
      command = "bash /etc/nixos/hosts/enterprise-base/switch.sh";
      options = [ "NOPASSWD" ];
    }];
  }];
}    
