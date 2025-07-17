#!/usr/bin/env bash
(
   set -euo pipefail

   cd /etc/nixos
   echo "preserving hardware-configuration.nix..."
   TEMP_HW=$(mktemp)
   sudo cp hardware-configuration.nix "$TEMP_HW"

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

   echo "restoring hardware-configuration.nix"
   sudo cp "$TEMP_HW" /etc/nixos/hardware-configuration.nix
   sudo chown root:root /etc/nixos/hardware-configuration.nix

   sudo nixos-rebuild switch --upgrade --flake /etc/nixos/#enterprise-base

   echo "Done!"
   sleep 2  # short pause before closing
) && exit
