#!/usr/bin/env bash
# script is useful for ensuring that the favourites menu in kickoff doesn't stagnate
# Refresh Plasma menus and favorites after an update
refresh_plasma_for_user() {
  local uid="$1" user="$2" rt="/run/user/$1"

  # Only touch sessions actually running Plasma
  if ! pgrep -u "$uid" -x plasmashell >/dev/null 2>&1; then
    return
  fi
  if [ ! -S "$rt/bus" ]; then
    echo "Skip $user; no user bus"
    return
  fi

  sudo -u "$user" env XDG_RUNTIME_DIR="$rt" DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" bash -c '
    set -e
    # Clear stale sycoca; rebuild; bounce the services that read it
    rm -f "$HOME/.cache/ksycoca"* || true
    if command -v kbuildsycoca6 >/dev/null 2>&1; then
      kbuildsycoca6 --noincremental || true
    elif command -v nix >/dev/null 2>&1; then
      nix run nixpkgs#kdePackages.kservice --command kbuildsycoca6 --noincremental || true
    else
      echo "kbuildsycoca6 not found; skipping rebuild"
    fi
    systemctl --user restart kactivitymanagerd.service || true
    systemctl --user restart plasma-plasmashell.service || true
  '
}

if command -v loginctl >/dev/null 2>&1; then
  # Handle all logged-in users
  while read -r uid user _; do
    refresh_plasma_for_user "$uid" "$user"
  done < <(loginctl list-users --no-legend 2>/dev/null)
else
  # Fallback to current user
  refresh_plasma_for_user "$(id -u)" "$(id -un)"
fi
