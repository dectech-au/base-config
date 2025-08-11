#etc/nixos/sys-modules/prometheus.nix
{ config, lib, pkgs, ... }:
{
  services.prometheus.exporters.node = {
    enable        = true;
    listenAddress = "127.0.0.1";
    port          = 9100;
    #openFirewall  = true;
  };
}
# Don't forget to add target's tailscale address to prometheus on the admin pc
