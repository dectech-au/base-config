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
serial=$(sudo cat /sys/class/dmi/id/product_serial 2>/dev/null | tr -d ' ')
[[ -z $serial || $serial == "Unknown" ]] && serial=$(cut -c1-8 /etc/machine-id)
hostname="dectech-${serial: -6}"

file=/etc/nixos/system-hostname.txt
if [[ ! -f $file || $(<"$file") != "$hostname" ]]; then
  echo "Updating hostname file → $hostname"
  echo "$hostname" | sudo tee "$file" >/dev/null
fi

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
if nixos-rebuild --help | grep -q -- --argstr; then
  # Modern Nix (≥ 2.18) – pure evaluation
  sudo nixos-rebuild switch \
       --upgrade \
       --flake /etc/nixos#personal-tim \
       --argstr host "$hostname" \
       --show-trace
else
  # Ancient binary – fall back to impure eval
  echo "[!] nixos-rebuild is prehistoric; using --impure"
  sudo nixos-rebuild switch \
       --upgrade \
       --flake /etc/nixos#personal-tim \
       --impure \
       --show-trace
fi

echo "[✓] system switched to $hostname"
