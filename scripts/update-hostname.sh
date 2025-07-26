#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Re-running as root..."
  exec sudo "$0" "$@"
fi

cd /etc/nixos

serial=$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null)
[[ -z "$serial" || "$serial" == "Unknown" ]] && serial=$(cut -c1-8 /etc/machine-id)
export DECTECH_HOSTNAME="dectech-${serial: -6}"

# continue with git reset, rebuild etc...
