#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  hostScript = ''
    #!/usr/bin/env bash

    serial="$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')"
    if [ -z "$serial" ] || [ "$serial" = "Unknown" ]; then
      serial="$(cut -c1-8 /etc/machine-id)"
    fi

    # Bash expands the slice; Nix ignores it thanks to the back-slash
    name="dectech-\${serial: -6}"

    if [ "$(cat /proc/sys/kernel/hostname)" != "$name" ]; then
      echo "setting hostname to $name"
      echo "$name" > /etc/hostname
      hostname "$name"
    fi
  '';
in
{
  # placeholder so evaluation has *some* hostname
  networking.hostName = lib.mkDefault "dectech-placeholder";

  # run the script on every activation
  system.activationScripts.generateHostName.text = hostScript;
}
