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
  # Harmless default, documented option.
  networking.hostName = lib.mkDefault "placeholder";  # MyNixOS: networking.hostName. :contentReference[oaicite:0]{index=0}

  # Run on every boot and every nixos-rebuild, AFTER /etc is populated.
  system.activationScripts.deriveHostname = {
    # Ordered fragments are supported; "etc" is a valid dependency example. 
    # This ensures our script runs late enough to override the static name. 
    deps = [ "etc" ];
    text = "${setHost}";
  };  # Activation scripts are the right hook here; see docs. :contentReference[oaicite:1]{index=1}

  # Optional: keep a manual trigger.
  systemd.services.dynamic-hostname = {
    description = "Set hostname from serial/machine-id";
    wantedBy = [ "multi-user.target" ];  # standard install hook. :contentReference[oaicite:2]{index=2}
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setHost}";
      Restart = lib.mkForce "no";
    };
  };
}
