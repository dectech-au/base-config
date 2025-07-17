#!/usr/bin/env bash
(
   set -euo pipefail

   cd /etc/nixox

   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_nixos_readonly
   git fetch origin
   git reset --hard origin/main

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

   sudo nixos-rebuild switch --upgrade --flake /etc/nixos/#enterprise-base

   echo "Done!"
   sleep 2  # short pause before closing
) && exit
