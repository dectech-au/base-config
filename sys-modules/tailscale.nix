#/etc/nixos/sys-modules/tailscale.nix
{ config, pkgs, lib, ... }:

let
  # Path inside the Nix store (or under /etc) where you’ll stash your Headscale API key
  hsKeyPath = "/etc/tailscale/hskey.txt";
in
{
  # Drop your key into /etc via Nix (or copy it there by hand)
  environment.etc."tailscale/hskey.txt".source = ./secrets/hskey.txt;

  services.tailscale = {
    enable              = true;
    useRoutingFeatures  = "client";

    # point tailscaled at your Headscale mesh
    authKeyFile         = hsKeyPath;                                             # :contentReference[oaicite:0]{index=0}
    extraUpFlags        = [
      "--login-server=https://headscale.dectech.au"                              # :contentReference[oaicite:1]{index=1}
      "--accept-dns=true"       # let Headscale DNS (MagicDNS + overrides) work
    ];

    # if you want tailscale to punch holes in your firewall
    openFirewall         = true;
  };
}
