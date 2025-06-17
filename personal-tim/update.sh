#!/usr/bin/env bash
(
   set -euo pipefail

   cd ${HOME}/.dotfiles/personal-tim
   git add *
   git commit -m "$(date '+%F_%H:%M:%S')" 
   git push origin main

   # Define the timestamp file
   STAMP_FILE="/tmp/nix_flake_update.timestamp"

   # Check if the file exists and if it's less than 10 minutes old
   if [[ ! -f "$STAMP_FILE" || $(($(date +%s) - $(< "$STAMP_FILE"))) -ge 600 ]]; then
    echo "Running nix flake update..."
    nix flake update
    date +%s > "$STAMP_FILE"
   else
    echo "Skipping nix flake update (ran recently)."
   fi

   sudo nixos-rebuild switch --upgrade --flake /home/dectec/.dotfiles/#personal-tim

   echo "Done!"
   sleep 2  # short pause before closing
) && exit
