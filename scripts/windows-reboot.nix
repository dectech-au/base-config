#/etc/nixos/flake-parts/windows-reboot.nix
{ config, lib, pkgs, ... }:
{
  security.sudo.extraRules = [
    {
      users = [ "ALL" ];
      commands = [
        {
          command = "sudo systemctl reboot --boot-loader-entry=auto-windows";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
