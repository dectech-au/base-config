#!/usr/bin/env bash
# /etc/nixos/bootstrap.sh
# 1. Mount BOOTSTRAP USB
# 2. Slurp GitHub token
# 3. Create / upload ED25519 deploy key (idempotent)
# 4. Clone /etc/nixos from repo
# 5. Rebuild system

set -euo pipefail

###############################################################################
# Config (override via env)
###############################################################################
USB_DEV="${USB_DEV:-/dev/disk/by-label/BOOTSTRAP}"
MOUNT_POINT="/mnt/bootstrap"
REPO="git@github.com:dectech-au/base-config.git"
SSH_KEY="/root/.ssh/id_ed25519_nixos"
FLAKE_TARGET="/etc/nixos#enterprise-base"
###############################################################################

[[ $EUID -eq 0 ]] || { echo "Run me as root, genius."; exit 1; }

# ── Locate BOOTSTRAP device (fallback if udev link missing) ──────────────────
if [[ ! -b "$USB_DEV" ]]; then
  USB_DEV="$(blkid -o device -t LABEL=BOOTSTRAP | head -n1 || true)"
fi
[[ -b "$USB_DEV" ]] || { echo "BOOTSTRAP USB not found"; exit 1; }

# ── Make sure git / curl / ssh exist – re-exec inside nix-shell once ─────────
need_pkg() { ! command -v "$1" &>/dev/null; }
if { need_pkg git || need_pkg curl || need_pkg ssh; } && [[ -z ${NIX_SHELL_REEXEC:-} ]]; then
  SCRIPT_PATH="$(readlink -f "$0")"
  exec env NIX_SHELL_REEXEC=1 nix-shell -p git curl openssh --run "bash $SCRIPT_PATH $*"
fi

# ── Mount USB & read token ───────────────────────────────────────────────────
mkdir -p "$MOUNT_POINT"
mount "$USB_DEV" "$MOUNT_POINT"
trap 'umount "$MOUNT_POINT" || true' EXIT

GITHUB_TOKEN="$(tr -d '\r\n' <"$MOUNT_POINT/github-token.txt")"
[[ -n "$GITHUB_TOKEN" ]] || { echo "Empty GitHub token"; exit 1; }

# ── Generate / reuse deploy key ──────────────────────────────────────────────
[[ -f "$SSH_KEY" ]] || ssh-keygen -t ed25519 -N '' -f "$SSH_KEY"
SSH_PUB_KEY="$(cat "${SSH_KEY}.pub")"

# ── Mirror hostname logic from hostname.nix ──────────────────────────────────
generate_hostname() {
  local serial
  serial="$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null || true)"
  [[ -z $serial || $serial == Unknown ]] && serial="$(cut -c1-8 /etc/machine-id)"
  printf 'dectech-%s' "${serial: -6}"
}
TITLE="$(generate_hostname)-$(date +%s)"

# ── Validate token ───────────────────────────────────────────────────────────
curl -sf -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user >/dev/null \
  || { echo "Invalid GitHub token"; exit 1; }

# ── Upload deploy key (idempotent) ───────────────────────────────────────────
status=$(
  curl -s -o /dev/null -w "%{http_code}" -X POST \
       -H "Authorization: token $GITHUB_TOKEN" \
       -d "{\"title\":\"$TITLE\",\"key\":\"$SSH_PUB_KEY\",\"read_only\":true}" \
       "https://api.github.com/repos/dectech-au/base-config/keys"
)
case $status in
  201) echo "Deploy key added";;
  422) echo "Deploy key already exists – carrying on";;
  *)   echo "GitHub API blew up with $status"; exit 1;;
esac

# GitHub edge may take a sec to notice new key
for _ in {1..10}; do
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -T git@github.com 2>/dev/null && break
  sleep 2
done

# ── Sync /etc/nixos ──────────────────────────────────────────────────────────
cd /etc/nixos
if [[ ! -d .git ]]; then
  git init
  git remote add origin "$REPO"
else
  git remote set-url origin "$REPO"
fi
git fetch --quiet origin
git reset --hard origin/main

# ── Start/reuse ssh-agent & add key ──────────────────────────────────────────
if ! ssh-add -l >/dev/null 2>&1; then
  eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add -q "$SSH_KEY"

echo "Bootstrap: config pulled, key loaded – rebuilding..."

nixos-rebuild switch --upgrade --flake "$FLAKE_TARGET" --show-trace
