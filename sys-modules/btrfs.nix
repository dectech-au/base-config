#~/.dotfiles/modules/btrfs.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    btrfs-progs
    parted
  ];
}
