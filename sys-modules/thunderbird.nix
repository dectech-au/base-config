#/etc/nixos/sys-modules/thunderbird.nix
{ config, lib, pkgs, ... }:
{
  programs.thunderbird.enable = true;
}
