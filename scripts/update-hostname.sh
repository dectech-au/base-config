#!/usr/bin/env bash
#/etc/nixos/scripts/update-hostname.sh

set -euo pipefail

serial=$(tr -d ' ' < /sys/class/dmi/id/product_serial 2>/dev/null || true)
[[ -z $serial || $serial == "Unknown" ]] && serial=$(cut -c1-8 /etc/machine-id)
hostname="dectech-${serial: -6}"

mod_dir="/etc/nixos/hosts/local"
mod_file="$mod_dir/host.nix"

sudo mkdir -p "$mod_dir"

if [[ ! -f $mod_file ]] || ! grep -q "$hostname" "$mod_file"; then
  echo "Writing host module → $hostname"
  sudo tee "$mod_file" >/dev/null <<EOF
{ ... }: {
  networking.hostName = "${hostname}";
}
EOF
fi
