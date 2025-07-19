#/etc/nixos/sys-modules/windows-reboot.nix
{ config, lib, pkgs, ... }:
{
  security.sudo.extraRules = [
    {
      users = [ "dectec" ];
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl reboot --boot-loader-entry=auto-windows";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
