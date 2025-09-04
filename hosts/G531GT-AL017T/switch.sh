#!/usr/bin/env bash
# /etc/nixos/hosts/G531GT-AL017T/switch.sh
# Pull → optional flake update → regenerate hostname module → nixos-rebuild

set -euo pipefail

###############################################################################
# Become root if needed, preserving args
###############################################################################
SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
if [[ $EUID -ne 0 ]]; then
  echo "[+] Re-execing as root"
  exec sudo -E bash "$SCRIPT" "$@"
fi

KEY="/root/.ssh/id_ed25519_nixos"
REPO_DIR="/etc/nixos"
FLAKE="/etc/nixos#G531GT-AL017T"
STAMP="/tmp/nix_flake_update.timestamp"

###############################################################################
# 1. Git pull with deploy key
###############################################################################
cd "$REPO_DIR"
eval "$(ssh-agent -s)" >/dev/null
SSH_OPTS="-i $KEY -o IdentitiesOnly=yes"
export GIT_SSH_COMMAND="ssh $SSH_OPTS"
ssh-add -l 2>/dev/null | grep -q "$KEY" || ssh-add -q "$KEY"
git fetch --quiet origin
git reset --hard origin/main


###############################################################################
# 2. nix flake update (max once every 10 min)
###############################################################################
now=$(date +%s)
if [[ ! -f $STAMP || $(( now - $(<"$STAMP") )) -ge 600 ]]; then
  echo "[+] nix flake update"
  nix flake update
  echo "$now" > "$STAMP"
else
  echo "[=] nix flake update skipped (<10 min since last run)"
fi

###############################################################################
# 3. Rebuild
###############################################################################

echo "[+] nixos-rebuild switch"
nixos-rebuild switch --flake "$FLAKE" --show-trace
bash /etc/nixos/scripts/refresh-plasma.sh
