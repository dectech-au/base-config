#./sys-modules/qbittorrent.nix
{ config, lib, pkgs, ... }:
{
  #services.qbittorrent.enable = true;
  environment.systemPackages = with pkgs; [
    qbittorrent-enhanced
  ];
}
