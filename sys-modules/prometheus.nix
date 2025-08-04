#etc/nixos/sys-modules/prometheus.nix
{ config, lib, pkgs, ... }:
{
  services.prometheus.exporters.node = {
    enable        = true;
    listenAddress = "0.0.0.0";
    port          = 9100;
    openFirewall  = true;
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
# Don't forget to add target's tailscale address to prometheus on the admin pc
