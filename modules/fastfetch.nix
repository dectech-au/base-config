#/etc/nixos/modules/fastfetch.nix
{ config, lib, pkgs, ... }:
{
  programs.fastfetch.enable = true;

  environment.systemPackages = with pkgs; [
    btrfs
    parted
  ];
}
