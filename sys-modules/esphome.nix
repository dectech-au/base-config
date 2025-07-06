#~/.dotfiles/sys-modules/esphome.nix
{ config, lib, pkgs, ... }:
{
  services.esphome = {
    enable = true;
  };
}
