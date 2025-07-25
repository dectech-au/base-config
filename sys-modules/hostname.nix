#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  hostScript = ''
#!/usr/bin/env bash

serial="$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')"
if [ -z "$serial" ] || [ "$serial" = "Unknown" ]; then
  serial="$(cut -c1-8 /etc/machine-id)"
fi

# \${…} keeps Nix from interpolating; Bash still expands it.
name="dectech-\${serial: -6}"

if [ "$(cat /proc/sys/kernel/hostname)" != "$name" ]; then
  echo "⚙️  setting hostname to $name"
  echo "$name" > /etc/hostname
  hostname "$name"
fi
'';
in
{
  # Placeholder so other modules have *some* hostname at eval time
  networking.hostName = lib.mkDefault "dectech-placeholder";

  # Runs inside the new system on every switch
  system.activationScripts.generateHostName = {
    text = hostScript;
  };
}
