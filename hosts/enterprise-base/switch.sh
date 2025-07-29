#!/usr/bin/env bash
# /etc/nixos/hosts/enterprise-base/switch.sh
set -euo pipefail

cd /etc/nixos

# ── Git pull ────────────────────────────────────────────────────────────
eval "$(ssh-agent -s)" >/dev/null

SSH_OPTS="-i /root/.ssh/id_ed25519_nixos -o IdentitiesOnly=yes"
export GIT_SSH_COMMAND="ssh $SSH_OPTS"

ssh-add -q /root/.ssh/id_ed25519_nixos
git fetch --quiet origin
git reset --hard origin/main

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
       --flake /etc/nixos#enterprise-base \
       --show-trace
