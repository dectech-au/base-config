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
  # Harmless default so evaluation/boot never fail
  networking.hostName = lib.mkDefault "placeholder";

  # Run *after* NixOS activation has finished setting the static name
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

  # Stop your network stack from rewriting the hostname later
  # If you use NetworkManager:
  networking.networkmanager.extraConfig = ''
    [main]
    hostname-mode=none
  '';

  # If you use dhcpcd instead, use this line and remove the NM block:
  # networking.dhcpcd.extraConfig = "nohook hostname\n";
}
