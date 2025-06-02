#/etc/nixos/modules/fastfetch.nix
{ config, lib, pkgs, ... }:
{
  programs.fastfetch.enable = true;
}
