#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:
{
system.activationScripts.generateHostName.text = ''
  serial=$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null)
  [ -z "$serial" -o "$serial" = "Unknown" ] && serial=$(cut -c1-8 /etc/machine-id)
  name="dectech-$${serial: -6}"

  if [ "$(cat /proc/sys/kernel/hostname)" != "$name" ]; then
    echo "setting hostname to $name"
    hostname "$name"        # kernel only – no file write
  fi
'';
}
