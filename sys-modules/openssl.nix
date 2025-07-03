#~/.dotfiles/sys-modules/openssl.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    openssl
  ];
}
