#~/.dotfiles/modules/kdeconnect.nix
{ config, lib, pkgs, ... }:
{
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = lib.range 1714 1764;
  };
}
