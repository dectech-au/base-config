#~/.dotfiles/sys-modules/virtualbox.nix
{ config, lib, pkgs, ... }:
{
  virtualisation.virtualbox.host.enable = true;
}
