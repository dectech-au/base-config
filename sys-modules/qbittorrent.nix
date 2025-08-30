#./sys-modules/qbittorrent.nix
{ config, lib, pkgs, ... }:
{
  services.qbittorrent.enable = true;
}
