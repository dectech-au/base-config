#~/.dotfiles/sys-modules/sshfs.nix
{ config, lib, pkgs, ... }:
{
  services.sshfs.enable = true;
}
