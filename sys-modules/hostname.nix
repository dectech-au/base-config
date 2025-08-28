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
  networking.hostName = lib.mkDefault "placeholder";

  # Ensure it runs after activation sets the static name
  systemd.services.dynamic-hostname = {
    description = "Set hostname from serial/machine-id";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "nixos-activation.service" ];
    requires    = [ "nixos-activation.service" ];
    before      = [ "network.target" "getty.target" "sshd.service" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${setHost}";
      Restart   = lib.mkForce "no";
    };
  };

  # Also run on every rebuild and boot after /etc is generated
  system.activationScripts.deriveHostname = {
    deps = [ "etc" ];
    text = "${setHost}";
  };

  # NetworkManager: stop it from changing the hostname
  networking.networkmanager.settings.main."hostname-mode" = "none";
}
