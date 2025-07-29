#!/usr/bin/env bash
# /etc/nixos/bootstrap.sh
set -euo pipefail

###############################################################################
# Config — tweak these if you really have to
###############################################################################
USB_DEV="${USB_DEV:-/dev/disk/by-label/BOOTSTRAP}" # where the thumb-drive lives
MOUNT_POINT="/mnt/bootstrap"
REPO="git@github.com:dectech-au/base-config.git"
SSH_KEY="/root/.ssh/id_ed25519_nixos"
###############################################################################

# ── Ensure we have tools ──────────────────────────────────────────────────────
if ! (command -v git >/dev/null && command -v curl >/dev/null && command -v ssh >/dev/null); then
  echo "Missing git/curl/ssh; dropping into nix-shell..."
  exec nix-shell -p git curl openssh --run "$0 $*"
fi

# ── Mount USB and read GitHub token ───────────────────────────────────────────
sudo mkdir -p "$MOUNT_POINT"
sudo mount "$USB_DEV" "$MOUNT_POINT"
trap 'sudo umount "$MOUNT_POINT" || true' EXIT  # always clean up

GITHUB_TOKEN="$(tr -d '\n' <"$MOUNT_POINT/github-token.txt")"

# ── Generate (or reuse) deploy key ────────────────────────────────────────────
if [[ ! -f "$SSH_KEY" ]]; then
  ssh-keygen -t ed25519 -N '' -f "$SSH_KEY"
fi
SSH_PUB_KEY="$(cat "${SSH_KEY}.pub")"

# ── Helper: replicate hostname logic from sys-module/hostname.nix ─────────────
generate_hostname() {
  serial="$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null || true)"
  if [[ -z "$serial" || "$serial" == "Unknown" ]]; then
    serial="$(cut -c1-8 /etc/machine-id)"
  fi
  printf 'dectech-%s' "$(printf '%s' "$serial" | tail -c 7 | tr -d '\n')"
}

TITLE="$(generate_hostname)-$(date +%s)"

# ── Upload key to GitHub (idempotent) ─────────────────────────────────────────
curl -sfL -H "Authorization: token $GITHUB_TOKEN" \
     -d "{\"title\":\"$TITLE\",\"key\":\"$SSH_PUB_KEY\",\"read_only\":true}" \
     https://api.github.com/repos/dectech-au/base-config/keys \
     || echo "GitHub: key may already exist – continuing anyway."

# ── Prepare /etc/nixos ────────────────────────────────────────────────────────
cd /etc/nixos
if [[ ! -d .git ]]; then
  git init
  git remote add origin "$REPO"
fi
git fetch --quiet origin
git reset --hard origin/main

# ── Fire up ssh-agent for subsequent `nixos-rebuild` pulls ────────────────────
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"

echo "✅ Bootstrap complete – system ready."
