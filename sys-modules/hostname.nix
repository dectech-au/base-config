# sys-modules/dynamic-hostname.nix
{ config, pkgs, lib, ... }:

let
  setHost = pkgs.writeShellScript "derive-hostname" ''
    set -euo pipefail
    serial=""
    if [ -r /sys/class/dmi/id/product_serial ]; then
      serial=$(tr -d ' \n' </sys/class/dmi/id/product_serial || true)
    fi
    if [ -z "$serial" ] && [ -r /etc/machine-id ]; then
      serial=$(cut -c1-8 /etc/machine-id || true)
    fi
    short=$(printf %s "$serial" | tail -c 6)
    name="dectech-$short"

    current=$(cat /proc/sys/kernel/hostname 2>/dev/null || true)
    if [ "$current" != "$name" ]; then
      /run/current-system/sw/bin/hostname "$name"
    fi
  '';
in {
  # Let transient hostname be used; do NOT set a static one
  networking.hostName = "";

  # Run early so getty, sshd, and DHCP see the final name
  systemd.services.dynamic-hostname = {
    description = "Set hostname from serial/machine-id";
    wantedBy    = [ "multi-user.target" ];
    before      = [ "network-pre.target" "network.target" "getty.target" "sshd.service" ];
    after       = [ "local-fs.target" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${setHost}";
      Restart   = lib.mkForce "no";
    };
  };

  # If you use NetworkManager, stop it touching the hostname
  networking.networkmanager.settings.main."hostname-mode" = "none";  # NM’s knob. :contentReference[oaicite:2]{index=2}

  # If you use dhcpcd, belt-and-braces:
  # dhcpcd only sets the hostname when it’s empty/localhost/nixos; after our unit runs, it won’t change it.
  # You can still hard-disable:
  # networking.dhcpcd.setHostname = false;  # option docs here. :contentReference[oaicite:3]{index=3}
}
