#etc/nixos/sys-modules/prometheus.nix
{ config, lib, pkgs, ... }:
{
  services.prometheus.exporters.node = {
    enable        = true;
    listenAddress = "0.0.0.0";
    port          = 9100;
    #openFirewall  = true;
  };
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9100 ];
}
# Don't forget to add target's tailscale address to prometheus on the admin pc
