#~/.dotfiles/sys-modules/ntfs.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ntfs3g
  ];
}
