#!/usr/bin/env bash
# /etc/nixos/bootstrap.sh
#
# Steps
# ──────────────────────────────────────────────────────────────────────────
# 1. Mount BOOTSTRAP USB, copy configuration-bootstrap.nix → /etc/nixos/configuration.nix
# 2. nixos-rebuild switch   (installs git / curl / ssh, enables flakes)
# 3. Create + upload ED25519 deploy key (idempotent)
# 4. Clone /etc/nixos from Git repo and hard-reset to main
# 5. nixos-rebuild switch   (final build with enterprise-base flake)

set -euo pipefail

###############################################################################
USB_DEV="${USB_DEV:-/dev/disk/by-label/BOOTSTRAP}"
MOUNT_POINT="/mnt/bootstrap"
BOOTSTRAP_CFG="configuration-bootstrap.nix"       # lives on the USB
REPO="git@github.com:dectech-au/base-config.git"
SSH_KEY="/root/.ssh/id_ed25519_nixos"
FLAKE_TARGET="${FLAKE_TARGET:-/etc/nixos#enterprise-base}"
SSH_OPTS="-i ${SSH_KEY} -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
export GIT_SSH_COMMAND="ssh ${SSH_OPTS}"
###############################################################################

[[ $EUID -eq 0 ]] || { echo "Run me as root."; exit 1; }

# ── Locate BOOTSTRAP partition ───────────────────────────────────────────────
if [[ ! -b $USB_DEV ]]; then
  USB_DEV="$(blkid -o device -t LABEL=BOOTSTRAP | head -n1 || true)"
fi
[[ -b $USB_DEV ]] || { echo "BOOTSTRAP USB not found."; exit 1; }

# ── Mount USB & copy bootstrap configuration ────────────────────────────────
mkdir -p "$MOUNT_POINT"
mount "$USB_DEV" "$MOUNT_POINT"
trap 'umount "$MOUNT_POINT" || true' EXIT

[[ -f "$MOUNT_POINT/$BOOTSTRAP_CFG" ]] \
  || { echo "$BOOTSTRAP_CFG not found on USB."; exit 1; }

echo "[+] Installing bootstrap configuration"
mkdir -p /etc/nixos
cp -f "$MOUNT_POINT/$BOOTSTRAP_CFG" /etc/nixos/configuration.nix

echo "[+] Initial rebuild to get git/ssh/curl"
nixos-rebuild switch --show-trace

# ── Read GitHub token ────────────────────────────────────────────────────────
GITHUB_TOKEN="$(tr -d '\r\n' <"$MOUNT_POINT/github-token.txt")"
[[ -n $GITHUB_TOKEN ]] || { echo "Empty GitHub token."; exit 1; }

# ── Deploy key management ────────────────────────────────────────────────────
[[ -f $SSH_KEY ]] || ssh-keygen -t ed25519 -N '' -f "$SSH_KEY"
ssh-add -l &>/dev/null || eval "$(ssh-agent -s)" >/dev/null
ssh-add -q "$SSH_KEY" || true
SSH_PUB_KEY="$(cat "${SSH_KEY}.pub")"

# ── Hostname helper (mirrors hostname.nix) ───────────────────────────────────
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
case $(
  curl -s -o /dev/null -w "%{http_code}" -X POST \
       -H "Authorization: token $GITHUB_TOKEN" \
       -d "{\"title\":\"$TITLE\",\"key\":\"$SSH_PUB_KEY\",\"read_only\":true}" \
       "https://api.github.com/repos/dectech-au/base-config/keys"
) in
  201) echo "Deploy key added.";;
  422) echo "Deploy key already exists – continuing.";;
  *)   echo "GitHub API error."; exit 1;;
esac

# ── Pre-seed known_hosts so first git doesn’t prompt ─────────────────────────
mkdir -p /root/.ssh
ssh-keyscan -H github.com >> /root/.ssh/known_hosts 2>/dev/null

# ── Wait (≤30 s) for edge to honour the key ──────────────────────────────────
for i in {1..15}; do
  git ls-remote --heads "$REPO" &>/dev/null && break
  sleep 2
  [[ $i -eq 15 ]] && { echo "GitHub still ignoring the key."; exit 1; }
done

# ── Clone / sync /etc/nixos ──────────────────────────────────────────────────
echo "[+] Pulling configuration repository"
cd /etc/nixos
git init -q 2>/dev/null || true
git remote add origin "$REPO" 2>/dev/null || git remote set-url origin "$REPO"
git fetch --quiet origin
git reset --hard origin/main

echo "[+] Final rebuild with enterprise-base flake"
nixos-rebuild switch --upgrade --flake "$FLAKE_TARGET" --show-trace

echo "✅ Bootstrap complete."
