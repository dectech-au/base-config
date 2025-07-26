# /etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

{
  systemd.services."systemd‑hostnamed".enable = false;  
  
  system.activationScripts.generateHostName.text = ''
    serial=$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null)
    if [ -z "$serial" ] || [ "$serial" = "Unknown" ]; then
      serial=$(cut -c1-8 /etc/machine-id)
    fi

    # get the last 6 characters safely without Bash substring syntax
    name="dectech-$(printf "%s" "$serial" | tail -c 7)"

    current=$(cat /proc/sys/kernel/hostname)
    if [ "$current" != "$name" ]; then
      echo "setting hostname to $name"
      hostname "$name"
    fi
  '';
}
