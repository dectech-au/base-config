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
# sudo bash /etc/nixos/scripts/update-hostname.sh

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

# --- Set hostname permanently... hopefully...
