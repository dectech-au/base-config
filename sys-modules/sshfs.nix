#~/.dotfiles/sys-modules/sshfs.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    sshfs
  ];
}

# how to use:
# sshfs remote_user@machine:/remote/directory ~/local/directory
