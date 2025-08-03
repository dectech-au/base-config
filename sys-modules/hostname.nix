# /etc/nixos/sys-modules/hostname.nix
{ config, lib, pkgs, ... }:

{
  services.dbus.enable = true;
  systemd.services."systemd‑hostnamed".enable = false;

  networking.networkmanager = {
    enable = true;
    settings.main.hostname-mode = "none";
  };

system.activationScripts.generateHostName.text = ''
  serial=$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null)
  if [ -z "$serial" ] || [ "$serial" = "Unknown" ]; then
    serial=$(cut -c1-8 /etc/machine-id)
  fi
  name="dectech-$(printf "%s" "$serial" | tail -c 7)"

  # only rewrite if it’s changed
  if [ "$(cat /etc/hostname 2>/dev/null)" != "$name" ]; then
    echo "$name" >/etc/hostname           ; # write the static hostname file
    hostnamectl set-hostname "$name"      ; # update kernel+hostnamed state
  fi
'';

}
