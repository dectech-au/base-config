#!/usr/bin/env bash
# /etc/nixos/bootstrap.sh
#
# 1. copy configuration-bootstrap.nix → /etc/nixos/configuration.nix
# 2. nixos-rebuild switch  (installs git/ssh/curl, enables flakes)
# 3. generate & upload deploy key
# 4. clone /etc/nixos repo, hard-reset to main
# 5. nixos-rebuild switch  (final build with enterprise-base flake)

set -euo pipefail

###############################################################################
BOOTSTRAP_DIR="$(dirname "$(readlink -f "$0")")"     # where the USB is mounted
BOOTSTRAP_CFG="configuration-bootstrap.nix"
TOKEN_FILE="github-token.txt"

REPO="git@github.com:dectech-au/base-config.git"
SSH_KEY="/root/.ssh/id_ed25519_nixos"
FLAKE_TARGET="${FLAKE_TARGET:-/etc/nixos#enterprise-base}"

SSH_OPTS="-i ${SSH_KEY} -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
export GIT_SSH_COMMAND="ssh ${SSH_OPTS}"
###############################################################################

[[ $EUID -eq 0 ]] || { echo "Run me as root."; exit 1; }

# ── 1. copy bootstrap configuration ──────────────────────────────────────────
[[ -f "$BOOTSTRAP_DIR/$BOOTSTRAP_CFG" ]] \
  || { echo "$BOOTSTRAP_CFG not found in $BOOTSTRAP_DIR"; exit 1; }

echo "[+] Installing bootstrap configuration"
mkdir -p /etc/nixos
cp -f "$BOOTSTRAP_DIR/$BOOTSTRAP_CFG" /etc/nixos/configuration.nix

# ── 2. first rebuild (brings in git/ssh/curl) ────────────────────────────────
echo "[+] Initial rebuild to enable flakes & tooling"
nixos-rebuild switch --show-trace

# ── read PAT after rebuild (curl now present) ────────────────────────────────
[[ -f "$BOOTSTRAP_DIR/$TOKEN_FILE" ]] \
  || { echo "$TOKEN_FILE not found in $BOOTSTRAP_DIR"; exit 1; }
GITHUB_TOKEN="$(tr -d '\r\n' <"$BOOTSTRAP_DIR/$TOKEN_FILE")"
[[ -n $GITHUB_TOKEN ]] || { echo "Empty GitHub token."; exit 1; }

# ── 3. deploy-key management ────────────────────────────────────────────────
[[ -f $SSH_KEY ]] || ssh-keygen -t ed25519 -N '' -f "$SSH_KEY"

# healthy agent? 0=keys,1=agent-no-keys,2=no agent
ssh-add -l &>/dev/null || st=$?
if [[ ${st:-0} -eq 2 ]]; then
  eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add -q "$SSH_KEY" || true
SSH_PUB_KEY="$(cat "${SSH_KEY}.pub")"

generate_hostname() {
  local serial
  serial="$(tr -d '[:space:]' </sys/class/dmi/id/product_serial 2>/dev/null || true)"
  [[ -z $serial || $serial == Unknown ]] && serial="$(cut -c1-8 /etc/machine-id)"
  serial="$(printf '%s' "$serial" | tr -cd '[:alnum:]')"
  printf 'dectech-%s' "${serial: -6}"
}
TITLE="$(generate_hostname)-$(date +%s)"

# validate token
curl -sf -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user >/dev/null \
  || { echo "Invalid GitHub token."; exit 1; }

# upload key (idempotent)
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

# accept GitHub host key
mkdir -p /root/.ssh
ssh-keyscan -H github.com >> /root/.ssh/known_hosts 2>/dev/null

# wait until the key propagates (≤30 s)
for i in {1..15}; do
  git ls-remote --heads "$REPO" &>/dev/null && break
  sleep 2
  [[ $i -eq 15 ]] && { echo "GitHub still ignoring the key."; exit 1; }
done

# ── 4. pull repo ─────────────────────────────────────────────────────────────
echo "[+] Pulling configuration repository"
cd /etc/nixos
git init -q 2>/dev/null || true
git remote add origin "$REPO" 2>/dev/null || git remote set-url origin "$REPO"
git fetch --quiet origin
git reset --hard origin/main

# ── 5. final rebuild ─────────────────────────────────────────────────────────
echo "[+] Final rebuild with enterprise-base flake"
nixos-rebuild switch --upgrade --flake "$FLAKE_TARGET" --show-trace

echo "✅ Bootstrap complete."
