#/etc/nixos/flake-parts/windows-reboot.nix
{ config, lib, pkgs, ... }:
{
  security.sudo.extraRules = [
    {
      users = [ "dectec" ];
      commands = [
        {
          command = "sudo systemctl reboot --boot-loader-entry=auto-windows";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
