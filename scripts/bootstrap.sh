#!/usr/bin/env bash
# /etc/nixos/bootstrap.sh
# 1. Mount BOOTSTRAP USB and read GitHub token
# 2. Create / upload ED25519 deploy key (idempotent)
# 3. Clone /etc/nixos from repo
# 4. nixos-rebuild switch

set -euo pipefail

###############################################################################
USB_DEV="${USB_DEV:-/dev/disk/by-label/BOOTSTRAP}"
MOUNT_POINT="/mnt/bootstrap"
REPO="git@github.com:dectech-au/base-config.git"
SSH_KEY="/root/.ssh/id_ed25519_nixos"
FLAKE_TARGET="${FLAKE_TARGET:-/etc/nixos#enterprise-base}"
###############################################################################

[[ $EUID -eq 0 ]] || { echo "Run me as root."; exit 1; }

# ── Locate BOOTSTRAP partition ───────────────────────────────────────────────
if [[ ! -b $USB_DEV ]]; then
  USB_DEV="$(blkid -o device -t LABEL=BOOTSTRAP | head -n1 || true)"
fi
[[ -b $USB_DEV ]] || { echo "BOOTSTRAP USB not found."; exit 1; }

# ── Ensure git/curl/ssh exist; fall into nix-shell once if missing ───────────
need_pkg() { ! command -v "$1" &>/dev/null; }
if { need_pkg git || need_pkg curl || need_pkg ssh; } && [[ -z ${NIX_SHELL_REEXEC:-} ]]; then
  command -v nix-shell &>/dev/null || { echo "Missing git/curl/ssh and nix-shell unavailable"; exit 1; }
  exec env NIX_SHELL_REEXEC=1 nix-shell -p git curl openssh \
       --run "bash \"$(readlink -f "$0")\""
fi

# ── Mount USB & read token ───────────────────────────────────────────────────
mkdir -p "$MOUNT_POINT"
mount "$USB_DEV" "$MOUNT_POINT"
trap 'umount "$MOUNT_POINT" || true' EXIT

GITHUB_TOKEN="$(tr -d '\r\n' <"$MOUNT_POINT/github-token.txt")"
[[ -n $GITHUB_TOKEN ]] || { echo "Empty GitHub token."; exit 1; }

# ── Deploy key management ────────────────────────────────────────────────────
[[ -f $SSH_KEY ]] || ssh-keygen -t ed25519 -N '' -f "$SSH_KEY"
SSH_PUB_KEY="$(cat "${SSH_KEY}.pub")"

# Healthy ssh-agent? 0 = keys present, 1 = agent alive & empty, 2 = no agent.
ssh-add -l &>/dev/null || status=$?
if [[ ${status:-0} -eq 2 ]]; then
  eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add -q "$SSH_KEY" || true   # idempotent

# ── Hostname helper (matches hostname.nix logic) ─────────────────────────────
generate_hostname() {
  local serial
  serial="$(tr -d '[:space:]' </sys/class/dmi/id/product_serial 2>/dev/null || true)"
  [[ -z $serial || $serial == Unknown ]] && serial="$(cut -c1-8 /etc/machine-id)"
  serial="$(printf '%s' "$serial" | tr -cd '[:alnum:]')"
  printf 'dectech-%s' "${serial: -6}"
}
TITLE="$(generate_hostname)-$(date +%s)"

# ── Validate token ───────────────────────────────────────────────────────────
curl -sf -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user >/dev/null \
  || { echo "Invalid GitHub token."; exit 1; }

# ── Upload deploy key (idempotent) ───────────────────────────────────────────
resp=$(
  curl -s -o /dev/null -w "%{http_code}" -X POST \
       -H "Authorization: token $GITHUB_TOKEN" \
       -d "{\"title\":\"$TITLE\",\"key\":\"$SSH_PUB_KEY\",\"read_only\":true}" \
       "https://api.github.com/repos/dectech-au/base-config/keys"
)
case $resp in
  201) echo "Deploy key added.";;
  422) echo "Deploy key already exists – continuing.";;
  *)   echo "GitHub API error $resp."; exit 1;;
esac

# ── Accept GitHub host key so git won't hang ─────────────────────────────────
mkdir -p /root/.ssh
ssh-keyscan -H github.com >> /root/.ssh/known_hosts 2>/dev/null

# Wait up to ~30 s for GitHub edge to honour the key
for i in {1..15}; do
  ssh -T git@github.com -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null &>/dev/null && break
  sleep 2
  [[ $i -eq 15 ]] && { echo "GitHub still ignoring the key."; exit 1; }
done

# ── Sync /etc/nixos ──────────────────────────────────────────────────────────
cd /etc/nixos
git init -q 2>/dev/null || true
git remote add origin "$REPO" 2>/dev/null || git remote set-url origin "$REPO"
git fetch --quiet origin
git reset --hard origin/main

echo "Bootstrap: repo synced – rebuilding..."

nixos-rebuild switch --upgrade --flake "$FLAKE_TARGET" --show-trace
