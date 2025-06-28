#~/.dotfiles/sys-modules/nextcloud.nix
{ config, lib, pkgs, ... }:
{
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud-default-hostname";
  };
}
