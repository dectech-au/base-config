#~/.dotfiles/sys-modules/flatpak.nix
{ config, lib, pkgs, ... }:
{
  services.flatpak.enable = true;
}
