#/etc/nixos/sys-modules/cursor.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    code-cursor
  ];
}
