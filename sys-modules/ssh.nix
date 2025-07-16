#/etc/nixos/sys-modules/ssh-add.nix
{ config, lib, pkgs, ... }:
{
  programs.ssh.startAgent = true;
}
