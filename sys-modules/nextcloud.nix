#~/.dotfiles/sys-modules/nextcloud.nix
{ config, lib, pkgs, ... }:
{
  environment.etc."nextcloud-admin-pass".text = "nextcloud1234";

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "localhost";
    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      dbtype = "sqlite";
    };
  };
}
