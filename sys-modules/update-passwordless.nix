{ config, lib, pkgs, ... }:
{
  security.sudo.extraRules = [{
    users = [ "dectec" ];
    commands = [{
      command = "/etc/nixos/hosts/enterprise-base/switch.sh";
      options = [ "NOPASSWD" ];
    }];
  }];
}    
