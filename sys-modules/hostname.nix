#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  hostScript = ''
    #!/usr/bin/env bash
    # read serial (or fallback)
    serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
    if [[ -z "$serial" || "$serial" == "Unknown" ]]; then
      serial=$(cut -c1-8 /etc/machine-id)
    fi

    # build dectech-<last 6 chars>
    name="dectech-${serial: -6}"

    # only switch if it’s wrong
    if [[ "$(cat /proc/sys/kernel/hostname)" != "$name" ]]; then
      echo "⚙️  setting hostname to $name"
      echo "$name" > /etc/hostname
      hostname "$name"
    fi
  '';
in {
  # so eval‐time modules don’t break
  networking.hostName = lib.mkDefault "dectech-placeholder";

  # this runs *after* your new system is built
  system.activationScripts.generateHostName = {
    text = hostScript;
    # no `deps` needed — /usr/bin/env and coreutils are on $PATH
  };
}
