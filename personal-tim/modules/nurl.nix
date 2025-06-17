#~/.dotfiles/modules/nurl.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nurl
  ];
}
