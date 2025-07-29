#!/usr/bin/env bash
# /etc/nixos/bootstrap.sh  – execute from BOOTSTRAP USB
#
# Steps
# ───────────────────────────────────────────────────────────────────────────
# 1. Copy configuration-bootstrap.nix  → /etc/nixos/configuration.nix
# 2. nixos-rebuild switch  (gets git/ssh/curl/sgdisk, enables flakes)
# 3. Detect the disk that holds “/” and relabel:
#       <disk>1 → boot-ssd
#       <disk>2 → dectech-enterprise-ssd
#       <disk>3 → swap-ssd
# 4. Verify labels
# 5. Generate + upload deploy key
# 6. Clone /etc/nixos repo, hard-reset to main
# 7. nixos-rebuild switch  (enterprise-base flake)

set -euo pipefail

###############################################################################
BOOTSTRAP_DIR="$(dirname "$(readlink -f "$0")")"
BOOTSTRAP_CFG="configuration-bootstrap.nix"
TOKEN_FILE="github-token.txt"

REPO="git@github.com:dectech-au/base-config.git"
SSH_KEY="/root/.ssh/id_ed25519_nixos"
FLAKE_TARGET="${FLAKE_TARGET:-/etc/nixos#enterprise-base}"

SSH_OPTS="-i ${SSH_KEY} -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
export GIT_SSH_COMMAND="ssh ${SSH_OPTS}"
###############################################################################

[[ $EUID -eq 0 ]] || { echo "Run me as root."; exit 1; }

# ── 1 ── copy bootstrap configuration ────────────────────────────────────────
cp -f "$BOOTSTRAP_DIR/$BOOTSTRAP_CFG" /etc/nixos/configuration.nix
echo "[+] Initial rebuild to enable flakes & tooling"
nixos-rebuild switch --show-trace

# ── 2 ── find the root disk & relabel partitions 1–3 ─────────────────────────
sudo bash /run/media/dectec/BOOTSTRAP/labels.sh

# ── 4 ── read GitHub token ───────────────────────────────────────────────────
GITHUB_TOKEN="$(tr -d '\r\n' <"$BOOTSTRAP_DIR/$TOKEN_FILE")"
[[ -n $GITHUB_TOKEN ]] || { echo "Empty GitHub token."; exit 1; }

# ── 5 ── deploy key management ───────────────────────────────────────────────
[[ -f $SSH_KEY ]] || ssh-keygen -t ed25519 -N '' -f "$SSH_KEY"
ssh-add -l &>/dev/null || eval "$(ssh-agent -s)" >/dev/null
ssh-add -q "$SSH_KEY" || true
SSH_PUB_KEY="$(cat "${SSH_KEY}.pub")"

generate_hostname() {
  local s
  s="$(tr -d '[:space:]' </sys/class/dmi/id/product_serial 2>/dev/null || true)"
  [[ -z $s || $s == Unknown ]] && s="$(cut -c1-8 /etc/machine-id)"
  printf 'dectech-%s' "$(printf '%s' "$s" | tr -cd '[:alnum:]' | tail -c6)"
}
TITLE="$(generate_hostname)-$(date +%s)"

curl -sf -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user >/dev/null \
  || { echo "Invalid GitHub token."; exit 1; }

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

mkdir -p /root/.ssh
ssh-keyscan -H github.com >> /root/.ssh/known_hosts 2>/dev/null

for _ in {1..15}; do
  git ls-remote --heads "$REPO" &>/dev/null && break
  sleep 2
done

# ── 6 ── pull repo & final rebuild ───────────────────────────────────────────
cd /etc/nixos
echo "[+] Pulling configuration repository"
git init -q 2>/dev/null || true
git remote add origin "$REPO" 2>/dev/null || git remote set-url origin "$REPO"
git fetch --quiet origin
git reset --hard origin/main

echo "[+] Final rebuild with enterprise-base flake"
nixos-rebuild switch --upgrade --flake "$FLAKE_TARGET" --show-trace

echo "✅ Bootstrap complete."
