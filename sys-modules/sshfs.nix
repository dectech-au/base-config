#~/.dotfiles/sys-modules/sshfs.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    sshfs
  ];
}
