#/etc/nixos/sys-modules/vlc.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vlc
  ];
}
