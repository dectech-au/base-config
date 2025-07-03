#~/.dotfiles/sys-modules/pinegrow.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pinegrow
  ];
}
