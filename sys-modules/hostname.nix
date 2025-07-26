#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  hostScript = ''
    #!/usr/bin/env bash

    serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
    if [ -z "$serial" ] || [ "$serial" = "Unknown" ]; then
      serial=$(cut -c1-8 /etc/machine-id)
    fi

    name="dectech-''${serial: -6}"

    if [ "$(cat /proc/sys/kernel/hostname)" != "$name" ]; then
      echo "setting hostname to $name"
      echo "$name" > /etc/hostname
      hostname "$name"
    fi
  '';
in
{
system.activationScripts.generateHostName.text = ''
  serial=$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null)
  [ -z "$serial" -o "$serial" = "Unknown" ] && serial=$(cut -c1-8 /etc/machine-id)
  name="dectech-${serial: -6}"

  if [ "$(cat /proc/sys/kernel/hostname)" != "$name" ]; then
    echo "setting hostname to $name"
    hostname "$name"        # kernel only – no file write
  fi
''


  # placeholder so eval-time modules have *some* value
  # networking.hostName = lib.mkDefault "dectech-placeholder";

  # run the bash snippet every switch / boot
  # system.activationScripts.generateHostName.text = hostScript;
}
