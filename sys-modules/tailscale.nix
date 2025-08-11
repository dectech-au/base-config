# /etc/nixos/sys-modules/tailscale.nix
{ config, pkgs, lib, ... }:
{
  services.tailscale = {
    enable               = true;
    openFirewall         = true;        # punches UDP/41641 etc.
    authKeyFile          = config.sops.secrets."tailscale/hskey.txt".path;   # Headscale pre-auth key
    useRoutingFeatures   = "client";    # you are not an exit node
    extraUpFlags         = [
      "--login-server=https://headscale.dectech.au"
      "--accept-dns=true"               # switch to false if you want local DNS
    ];
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
#  -o json | jq -r '.key' > /root/.secrets/hskey.txt
#
# 4. copy contents of this hskey, to the clients ssh module's authorizedkeys.keys = [ "<string>" ];
# 5. add the target url to the server's prometheus.nix module
