#!/usr/bin/env bash
#/etc/nixos/bootstrap/bootstrap.sh
set -euo pipefail

# --- Step 0: first-generation detection -------------------------------------------------

if [[ $(nixos-rebuild list-generations | awk '/current/ {print $1}') -eq 1 ]]; then
  echo "[+] First boot: staging temporary configuration"
  sudo mkdir -p /mnt
  sudo mount /dev/disk/by-partlabel/dectech /mnt
  sudo cp /mnt/home/dectec/.dotfiles/bootstrap/bootstrap-configuration.nix /etc/nixos/configuration.nix
  sudo nixos-rebuild switch
fi

cd /etc/nixos

# --- Step 1: ensure host module exists --------------------------------------------------

	sudo chmod +x /etc/nixos/bootstrap/update-hostname.sh
	/etc/nixos/bootstrap/update-hostname.sh
 
# --- Step 2: create read-only deploy key on GitHub --------------------------------------

SSH_KEY="$HOME/.ssh/id_nixos_readonly"

if [[ ! -f $SSH_KEY ]]; then
  echo "[+] Generating deploy key"
  ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "nixos-readonly"

  GITHUB_TOKEN=$(tr -d '\n' < /mnt/home/dectec/.dotfiles/bootstrap/github-token.txt)
  GITHUB_USER="dectech-au"
  GITHUB_REPO="base-config"

  echo "[+] Uploading deploy key to GitHub"
  curl -s \
       -H "Authorization: token $GITHUB_TOKEN" \
       -H "Accept: application/vnd.github.v3+json" \
       -d @- \
       "https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/keys" <<EOF
{
  "title": "$(cat hosts/local/host.nix | grep hostName | cut -d'"' -f2)-$(date +%s)",
  "key": "$(cat "${SSH_KEY}.pub")",
  "read_only": true
}
EOF
  unset GITHUB_TOKEN
fi

# --- Step 3: pull/update the flake repo ------------------------------------------------

eval "$(ssh-agent -s)" >/dev/null
ssh-add -q "$SSH_KEY"

git fetch --quiet origin || git clone git@github.com:dectech-au/base-config.git .
git reset --hard origin/main

# --- Step 4: flake-lock update (10 minutes) --------------------------------------------

stamp=/tmp/nix_flake_update.timestamp
if [[ ! -f $stamp || $(( $(date +%s) - $(< $stamp) )) -ge 600 ]]; then
  echo "[+] nix flake update"
  nix flake update
  date +%s > $stamp
fi

# --- Step 5: pure rebuild ---------------------------------------------------------------

sudo nixos-rebuild switch --flake /etc/nixos#enterprise-base --show-trace
echo "[✓] bootstrap finished"
