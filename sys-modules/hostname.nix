#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  hostScript = ''
#!/usr/bin/env bash

serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
if [[ -z "$serial" || "$serial" == "Unknown" ]]; then
  serial=$(cut -c1-8 /etc/machine-id)
fi

# this ${serial: -6} is inside a Nix single-quoted literal—bash, not Nix, will handle it
name="dectech-${serial: -6}"

if [[ "$(cat /proc/sys/kernel/hostname)" != "$name" ]]; then
  echo "⚙️  setting hostname to $name"
  echo "$name" > /etc/hostname
  hostname "$name"
fi
'';  # <-- close the literal with two ASCII single-quotes

in {
  networking.hostName = lib.mkDefault "dectech-placeholder";

  system.activationScripts.generateHostName = {
    text = hostScript;
  };
}

