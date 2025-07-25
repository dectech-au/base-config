#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  # This is *just* the shell snippet that computes the hostname.
  hostScript = ''
    #!/usr/bin/env bash
    serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
    if [[ -z "$serial" || "$serial" == "Unknown" ]]; then
      serial=$(cut -c1-8 /etc/machine-id)
    fi
    name="dectech-${serial: -6}"

    # only change if different
    if [[ "$(cat /proc/sys/kernel/hostname)" != "$name" ]]; then
      echo "⚙️  setting hostname to $name"
      echo "$name" > /etc/hostname
      hostname "$name"
    fi
  '';
in {
  # a harmless placeholder so evaluation still sees a hostname
  networking.hostName = lib.mkDefault "dectech-placeholder";

  # activationScripts runs *after* the new system is built, so touching
  # /etc/hostname here doesn’t break purity of the evaluation phase
  system.activationScripts.generateHostName = {
    text = hostScript;
    # ensure bash, coreutils, etc. are available
    deps = [ pkgs.bash pkgs.coreutils pkgs.util-linux ];
  };
}
