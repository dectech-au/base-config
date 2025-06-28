#~/.dotfiles/sys-modules/nextcloud.nix
{ config, lib, pkgs, ... }:
{
  services.nextcloud = {
    enable = true;
    hostName = "localhost";
    adminpassFile = "/etc/nextcloud-admin-pass";
  };
}
