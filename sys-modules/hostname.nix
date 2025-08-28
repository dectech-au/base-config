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
  # do not write /etc/hostname
  networking.hostName = lib.mkForce "";

  # run before networking is brought up
  systemd.services.dynamic-hostname = {
    description = "Set hostname from serial/machine-id";
    wantedBy    = [ "network-pre.target" ];
    after       = [ "local-fs.target" ];
    before      = [ "network-pre.target" "getty.target" "sshd.service" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${setHost}";
      Restart   = lib.mkForce "no";
    };
  };

  # prevent NM from messing with the transient hostname
  networking.networkmanager.settings.main."hostname-mode" = "none";  # disables NM’s transient-hostname updates. :contentReference[oaicite:1]{index=1}

  # if you use dhcpcd instead of NM, disable its hostname writes
  # it only writes when the hostname is empty/localhost/nixos
  # networking.dhcpcd.setHostname = false;  # option exists; default true. :contentReference[oaicite:2]{index=2}
}
