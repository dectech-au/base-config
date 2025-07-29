{ config, lib, pkgs, ... }:
{
  security.sudo.extraRules = [{
    users = [ "dectec" ];
    commands = [{
      command = "sudo bash /etc/nixos/hosts/enterprise-base/switch.sh";
      options = [ "NOPASSWD" ];
    }];
  }];
}    
