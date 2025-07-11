#~/.dotfiles/sys-modules/htop.nix
{ config, lib, pkgs, ... }:
{
  services.htop.enable = true;
}
