#/etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:
{
  system.activationScripts.generateHostName.text = ''
    serial=$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null)
    [ -z "$serial" ] || [ "$serial" = "Unknown" ] && serial=$(cut -c1-8 /etc/machine-id)
  
    suffix=$(echo "$serial" | tail -c 7)
    name="dectech-$suffix"
  
    if [ "$(cat /proc/sys/kernel/hostname)" != "$name" ]; then
      echo "setting hostname to $name"
      hostname "$name"
    fi
  '';
}
