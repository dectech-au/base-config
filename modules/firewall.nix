#~/.dotfiles/modules/firewall.nix
{ config, lib, pkgs, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 6666 ]; # remote mouse
    allowedUDPPorts = [ 6666 ]; # remote mouse 
  };
}
