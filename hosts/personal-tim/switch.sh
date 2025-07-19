#!/usr/bin/env bash
(
   set -euo pipefail
   cd /etc/nixos

# --- Git pull -----------------------------------------------
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_nixos_readonly
   git fetch origin
   git reset --hard origin/main

# --- Refresh hostname file every time -----------------------
   SERIAL=$(sudo cat /sys/class/dmi/id/product_serial | tr -d ' ')
  [[ -z "$SERIAL" || "$SERIAL" == "Unknown" ]] && \
     SERIAL=$(cat /etc/machine-id | cut -c1-8)
   HOSTNAME="dectech-${SERIAL: -6}"
   
  FILE=/etc/nixos/system-hostname.txt
   if [[ ! -f $FILE || $(< "$FILE") != "$HOSTNAME" ]]; then
     echo "Updating hostname file → $HOSTNAME"
     echo "$HOSTNAME" | sudo tee "$FILE" >/dev/null
   fi

# --- flake-update throttle ----------------------------------

   STAMP_FILE="/tmp/nix_flake_update.timestamp"

   # Check if the file exists and if it's less than 10 minutes old
   if [[ ! -f "$STAMP_FILE" || $(($(date +%s) - $(< "$STAMP_FILE"))) -ge 600 ]]; then
    echo "Running nix flake update..."
    nix flake update
    date +%s > "$STAMP_FILE"
   else
    echo "Skipping nix flake update (ran recently)."
   fi

   HOSTNAME="dectech-${SERIAL: -6}"
   
sudo nixos-rebuild switch \
      --upgrade \
      --flake /etc/nixos/#personal-tim \
      --argstr host "$HOSTNAME"
      --show-trace

   echo "Done!"
   sleep 2  # short pause before closing
) && exit
