#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  hostScript = ''  # ← two single‐quotes, not double
    #!/usr/bin/env bash

    serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
    if [[ -z "$serial" || "$serial" == "Unknown" ]]; then
      serial=$(cut -c1-8 /etc/machine-id)
    fi

    # this ${serial: -6} runs in bash, not Nix
    name="dectech-${serial: -6}"

    if [[ "$(cat /proc/sys/kernel/hostname)" != "$name" ]]; then
      echo "⚙️  setting hostname to $name"
      echo "$name" > /etc/hostname
      hostname "$name"
    fi
  '';  # ← close the literal

in {
  # give Nix something at eval time
  networking.hostName = lib.mkDefault "dectech-placeholder";

  # run the above script after rebuild, inside the new system
  system.activationScripts.generateHostName = {
    text = hostScript;
  };
}
