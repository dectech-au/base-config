#~/.dotfiles/sys-modules/tailscale.nix
{ config, lib, pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
}
