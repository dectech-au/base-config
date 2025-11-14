#/etc/nixos/sys-modules/headscale.nix
{ config, lib, pkgs, ... }:
{
  services.headscale = {
    enable = true;
    user = "dectec";
    group = "dectec";
    # port = 443

  };
}
