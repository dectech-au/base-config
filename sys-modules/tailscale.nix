# /etc/nixos/sys-modules/tailscale.nix
{ config, pkgs, lib, ... }:

let
  hsKeyPath = "/etc/tailscale/hskey.txt";
in
{
  # Ensure headscale.dectech.au resolves to your SWAG/LAN IP
  # networking.hosts = lib.mkForce {
  #  "headscale.dectech.au" = [ "192.168.1.157" ];
  # };

  # copy the file from your home dir into /etc/tailscale/hskey.txt
  environment.etc."tailscale/hskey.txt".source = "/home/dectec/.secrets/hskey.txt";

  services.tailscale = {
    enable         = true;
    authKeyFile    = hsKeyPath;
    useRoutingFeatures = "client";
    extraUpFlags   = [
      "--login-server=https://headscale.dectech.au"
      "--accept-dns=true"
      "--tun=userspace-networking"
    ];
    openFirewall   = true;
  };
}

# How to use:
# 1. Create new user on headscale:
# sudo headscale users create <NEW_USERNAME>
#
# 2. List ID # for user:
# sudo headscale users list
#
# 3. Create the key
# sudo headscale preauthkeys create \
#  --user <ID> \
#  --reusable \
#  --expiration 24h \
#  -o json | jq -r '.key' > ~/.secrets/hskey.txt
