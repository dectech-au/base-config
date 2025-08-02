# /etc/nixos/sys-modules/tailscale.nix
{ config, pkgs, lib, ... }:

let
  hsKeyPath = "/etc/tailscale/hskey.txt";
in
{
  # copy the file from your home dir into /etc/tailscale/hskey.txt
  environment.etc."tailscale/hskey.txt".source = "/home/dectec/.secrets/hskey.txt";

  services.tailscale = {
    enable         = true;
    authKeyFile    = hsKeyPath;
    useRoutingFeatures = "client";
    extraUpFlags   = [
      "--login-server=https://headscale.dectech.au"
      "--accept-dns=true"
    ];
    openFirewall   = true;
  };
}
