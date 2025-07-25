#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  # This must be a literal Nix string, not a function
  hostScript = ''
    #!/usr/bin/env bash
    serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
    if [[ -z "$serial" || "$serial" == "Unknown" ]]; then
      serial=$(cut -c1-8 /etc/machine-id)
    fi
    name="dectech-${serial: -6}"

    # Only change if it’s different
    if [[ "$(cat /proc/sys/kernel/hostname)" != "$name" ]]; then
      echo "⚙️  setting hostname to $name"
      echo "$name" > /etc/hostname
      hostname "$name"
    fi
  '';
in
{
  # A harmless placeholder so evaluation-time modules don’t break
  networking.hostName = lib.mkDefault "dectech-placeholder";

  # Activation script runs inside the new system after build
  system.activationScripts.generateHostName = {
    text = hostScript;    # plain string, no interpolation of functions
    # deps can be omitted—bash, cat, etc. are on the default PATH
  };
}
