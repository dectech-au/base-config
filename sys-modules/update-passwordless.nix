{ config, lib, pkgs, ... }:
{
  security.sudo.extraRules = [{
    users = [ "dectec" ];
    commands = [{
      command = "/run/current-system/sw/bin/nixos-rebuild";
      options = [ "NOPASSWD" ];
    }];
  }];
}    
