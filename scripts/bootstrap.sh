#!/usr/bin/env bash
# /etc/nixos/bootstrap.sh  —  USB-side version
#
# 1. copy configuration-bootstrap.nix -> /etc/nixos/configuration.nix
# 2. nixos-rebuild switch  (installs git/ssh/curl, enables flakes)
# 3. relabel GPT parts:  / → dectech-enterprise, /boot → boot, swap → swap
# 4. create & upload deploy key
# 5. git pull /etc/nixos, hard-reset to main
# 6. nixos-rebuild switch  (enterprise-base flake)

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

cp -f "$BOOTSTRAP_DIR/$BOOTSTRAP_CFG" /etc/nixos/configuration.nix
echo "[+] Initial rebuild to enable flakes & tooling"
nixos-rebuild switch --show-trace

# ── relabel helper ——— -------------------------------------------------------
ensure_label() {
  local node="$1" want="$2"

  # Resolve mountpoint -> device if a path
  local dev
  if [[ $node == /* && ! -b $node ]]; then
    dev="$(findmnt -n -o SOURCE "$node")" || return
  else
    dev="$node"
  fi
  dev="$(readlink -f "$dev")"               # chase /dev/disk/by-* symlink

  # Pull partition number from blkid udev info
  local info pnum disk
  info="$(blkid -o udev "$dev")" || return
  pnum="$(grep -m1 '^ID_PART_ENTRY_NUMBER=' <<<"$info" | cut -d= -f2)"

  # Derive the parent disk path
  if [[ $dev =~ ^(/dev/nvme[0-9]+n[0-9]+)p[0-9]+$ ]]; then
    disk="${BASH_REMATCH[1]}"
  elif [[ $dev =~ ^(/dev/[a-z]+)[0-9]+$ ]]; then
    disk="${BASH_REMATCH[1]}"
  else
    echo "Cannot parse parent disk of $dev" ; return
  fi

  local current
  current="$(blkid -s PARTLABEL -o value "$dev" || true)"
  if [[ $current != "$want" ]]; then
    echo "    • relabelling $dev → $want"
    sgdisk -c "${pnum}:${want}" "$disk" >/dev/null
  fi
}

echo "[+] Ensuring GPT partition labels"
ensure_label /       dectech-enterprise
ensure_label /boot   boot
swapdev="$(awk 'NR==2 {print $1}' /proc/swaps || true)"
[[ -n $swapdev ]] && ensure_label "$swapdev" swap

# ── GitHub token, deploy-key upload, repo pull, final rebuild — unchanged ───
# (remaining script identical to previous iteration)
