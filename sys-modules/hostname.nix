#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

let
  # Helper that returns a deterministic suffix *on that machine*.
  # • Use product serial when it exists and isn’t “Unknown”.
  # • Fall back to the first 8 chars of machine-id.
  # • Always feed it through ‘tail -c 7’ -> “ABCDEF” → “BCDEF”.
  generator = ''
    serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
    if [ -z "$serial" ] || [ "$serial" = "Unknown" ]; then
      serial=$(cut -c1-8 /etc/machine-id)
    fi
    echo "dectech-${serial: -6}"
  '';
in
{
  #### 1. Build-time placeholder (required by a few services) ####
  # We give Nix _some_ value so any modules that look at
  # ‘networking.hostName’ during evaluation don’t choke.  It will be
  # overwritten at activation.
  networking.hostName = lib.mkDefault "dectech-placeholder";

  #### 2. Activation script that sets the *real* hostname #########
  # Runs on every switch; does nothing if the hostname is already correct.
  system.activationScripts.generateHostName.text = ''
    wanted="$(${generator})"
    current=$(cat /proc/sys/kernel/hostname)

    if [ "$current" != "$wanted" ]; then
      echo "⚙️  setting hostname to $wanted"
      echo "$wanted" > /etc/hostname
      # hostnamed is locked down on NixOS, so use the classic tool:
      hostname "$wanted"
    fi
  '';
}
