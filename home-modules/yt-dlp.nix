#/etc/nixos/home-modules/yt-dlp.nix
{ config, lib, pkgs, ... }:
{
  programs.yt-dlp.enable = true;
}
