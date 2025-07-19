#/etc/nixos/sys-modules/windows-reboot.nix
{ config, lib, pkgs, ... }:
{
  security.sudo.extraRules = [
    {
      users = [ "ALL" ];
      commands = [
        {
          command = "sudo ${pkgs.systemd}/bin/systemctl reboot --boot-loader-entry=auto-windows";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
