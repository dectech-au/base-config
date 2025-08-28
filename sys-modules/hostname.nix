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
  # Harmless default; valid option. :contentReference[oaicite:0]{index=0}
  networking.hostName = lib.mkDefault "placeholder";

  systemd.services.dynamic-hostname = {
    description = "Set hostname from serial/machine-id";
    wantedBy    = [ "multi-user.target" ];  # install target. :contentReference[oaicite:1]{index=1}

    # Run early, before login and network
    unitConfig = {
      DefaultDependencies = false;                        # valid under [Unit]. :contentReference[oaicite:2]{index=2}
      Before = [ "network-pre.target" "network.target" "getty.target" "sshd.service" ];
      After  = [ "local-fs.target" ];
    };

    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${setHost}";
      Restart   = lib.mkForce "no";                       # oneshot must not have Restart. :contentReference[oaicite:3]{index=3}
    };
  };
}
