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
      echo "Setting kernel hostname to $name"
      /run/current-system/sw/bin/hostname "$name"
    fi
  '';
in {
  # Valid option; gives a harmless default before our unit runs.
  networking.hostName = lib.mkDefault "placeholder";  # :contentReference[oaicite:1]{index=1}

  systemd.services.dynamic-hostname = {
    description = "Set hostname from serial/machine-id";
    wantedBy    = [ "multi-user.target" ];             # :contentReference[oaicite:2]{index=2}
    unitConfig.Before = [ "network.target" ];          # Unit-level knob lives under unitConfig. :contentReference[oaicite:3]{index=3}
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${setHost}";
      Restart   = lib.mkForce "no";                    # oneshot cannot use Restart=always/on-success. :contentReference[oaicite:4]{index=4}
    };
  };

  # Optional, but nice: also run on every switch so rebuilds pick up the new name immediately.
  system.activationScripts.dynamic-hostname.text = "${setHost}";  # Runs at boot and nixos-rebuild. :contentReference[oaicite:5]{index=5}
}
