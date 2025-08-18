#!/usr/bin/env bash
# script is useful for ensuring that the favourites menu in kickoff doesn't stagnate

# ----- Plasma refresh, immediate only -----
log() { echo "[plasma-refresh] $(date +'%F %T') $*"; }

_refresh_user_now() {
  local uid="$1" user="$2" rt="/run/user/$1"
  log "Refreshing for user=$user uid=$uid"

  # Rebuild sycoca as the target user; no DBus needed
  sudo -u "$user" bash -lc '
    set -e
    echo "  -> Clearing $HOME/.cache/ksycoca*"
    rm -f "$HOME/.cache/ksycoca"* || true

    export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/run/current-system/sw/share:/usr/local/share:/usr/share}"
    if command -v kbuildsycoca6 >/dev/null 2>&1; then
      echo "  -> kbuildsycoca6 --noincremental"
      kbuildsycoca6 --noincremental || true
    elif command -v nix >/dev/null 2>&1; then
      echo "  -> nix run nixpkgs#kdePackages.kservice -- kbuildsycoca6"
      nix run nixpkgs#kdePackages.kservice --command kbuildsycoca6 --noincremental || true
    else
      echo "  !! kbuildsycoca6 not found and nix not available; skipped rebuild"
    fi
  '

  # Only try to touch session services if the user has a session bus
  if [ -S "$rt/bus" ]; then
    log "Attempting user service restarts for $user"
    sudo -u "$user" env DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" bash -lc '
      # Restart only if present; ignore failures
      echo "  -> systemctl --user try-restart kactivitymanagerd.service"
      systemctl --user try-restart kactivitymanagerd.service || true

      echo "  -> systemctl --user try-restart plasma-plasmashell.service"
      systemctl --user try-restart plasma-plasmashell.service || true

      echo "  -> kactivitymanagerd status:"
      systemctl --user is-active kactivitymanagerd.service >/dev/null && echo "     active" || echo "     inactive"

      echo "  -> plasmashell status:"
      systemctl --user is-active plasma-plasmashell.service >/dev/null && echo "     active" || echo "     inactive"
    '
  else
    log "No DBus session for $user; skipped restarts, cache already rebuilt"
  fi

  log "Done for $user"
}

run_plasma_refresh_now() {
  log "Scanning logged-in users"
  if command -v loginctl >/dev/null 2>&1; then
    loginctl list-users --no-legend 2>/dev/null | while read -r uid user _; do
      [ -n "$uid" ] && [ -n "$user" ] || continue
      _refresh_user_now "$uid" "$user"
    done
  else
    log "loginctl not found; falling back to current user"
    _refresh_user_now "$(id -u)" "$(id -un)"
  fi
  log "Plasma refresh complete"
}

# Call from your update flow
run_plasma_refresh_now
