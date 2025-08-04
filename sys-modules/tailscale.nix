# /etc/nixos/sys-modules/tailscale.nix
{ config, pkgs, lib, ... }:
{
  # Ensure headscale.dectech.au resolves to your SWAG/LAN IP
  # networking.hosts = lib.mkForce {
  #  "headscale.dectech.au" = [ "192.168.1.157" ];
  # };

  environment.systemPackages = with pkgs; [
    jq
  ];

  services.tailscale = {
    enable         = true;
    authKeyFile    = /etc/tailscale/hskey.txt;
    useRoutingFeatures = "client";
    extraUpFlags   = [
      "--login-server=https://headscale.dectech.au"
      "--accept-dns=true"
      "--tun=userspace-networking"
    ];
    openFirewall   = true;
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

}

# How to use:
# 1. Create new user on headscale:
# sudo headscale users create <NEW_USERNAME>
#
# 2. List ID # for user:
# sudo headscale users list
#
# 3. Create the key
# sudo mkdir -p /var/lib/tailscale
# sudo headscale preauthkeys create \
#  --user <ID> \
#  --reusable \
#  --expiration 24h \
#  -o json | jq -r '.key' > /etc/tailscale/hskey.txt
#
# 4. copy contents of this hskey, to the clients ssh module's authorizedkeys.keys = [ "<string>" ];
# 5. add the target url to the server's prometheus.nix module
