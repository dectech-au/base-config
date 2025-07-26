#!/usr/bin/env bash
# /etc/nixos/hosts/personal-tim/switch.sh
set -euo pipefail

cd /etc/nixos

# ── Git pull ────────────────────────────────────────────────────────────
eval "$(ssh-agent -s)" >/dev/null
ssh-add -q ~/.ssh/id_nixos_readonly
git fetch --quiet origin
git reset --hard origin/main

# ── Build /etc/nixos/system-hostname.txt every run ──────────────────────
sudo bash /etc/nixos/scripts/update-hostname.sh


#serial=$(sudo cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
#[[ -z $serial || $serial == "Unknown" ]] && serial=$(cut -c1-8 /etc/machine-id)
#hostname="dectech-${serial: -6}"

#file=/etc/nixos/hosts/system-hostname.txt
#if [[ ! -f $file || $(<"$file") != "$hostname" ]]; then
#  echo "Updating hostname file → $hostname"
#  echo "$hostname" | sudo tee "$file" >/dev/null
#fi

#cat <<EOF | sudo tee /etc/nixos/hosts/hostname.nix >/dev/null
#{ config, lib, pkgs, ... }:
#{
#  networking.hostName = "${hostname}";
#}
#EOF

# ── Throttle nix flake update to once per 10 min ────────────────────────
stamp=/tmp/nix_flake_update.timestamp
if [[ ! -f $stamp || $(( $(date +%s) - $(<"$stamp") )) -ge 600 ]]; then
  echo "[+] nix flake update"
  nix flake update
  date +%s >"$stamp"
else
  echo "[=] nix flake update skipped (run <10 min ago)"
fi

# ── Rebuild ─────────────────────────────────────────────────────────────

  sudo nixos-rebuild switch \
       --upgrade \
       --flake /etc/nixos#personal-tim \
       --show-trace
