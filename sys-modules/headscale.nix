#/etc/nixos/sys-modules/netbird.nix
{ config, lib, pkgs, ... }:
{
  services.headscale = {
    enable = true;
    user = "dectec";
    group = "dectec";
    # port = 443

  };
}
