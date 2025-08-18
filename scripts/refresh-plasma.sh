#!/usr/bin/env bash
# script is useful for ensuring that the favourites menu in kickoff doesn't stagnate
# Refresh Plasma menus and favorites after an update
# Refresh Plasma menus and favorites after an update, with logging
log() { echo "[plasma-refresh] $(date +'%F %T') $*"; }

refresh_plasma_for_user() {
  local uid="$1" user="$2" rt="/run/user/$1"

  log "Start for user=$user uid=$uid"

  if ! pgrep -u "$uid" -x plasmashell >/dev/null 2>&1; then
    log "Skip $user, plasmashell is not running"
    return
  fi
  if [ ! -S "$rt/bus" ]; then
    log "Skip $user, no DBus session at $rt/bus"
    return
  fi

  log "Preparing to refresh caches for $user"
  sudo -u "$user" env XDG_RUNTIME_DIR="$rt" DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" bash -c '
    set -e

    echo "  -> Removing $HOME/.cache/ksycoca*"
    rm -f "$HOME/.cache/ksycoca"* || true
    echo "  -> Removed sycoca cache files"

    if command -v kbuildsycoca6 >/dev/null 2>&1; then
      echo "  -> Rebuilding sycoca with kbuildsycoca6"
      if kbuildsycoca6 --noincremental; then
        echo "     sycoca rebuild OK"
      else
        echo "     sycoca rebuild failed"
      fi
    elif command -v nix >/dev/null 2>&1; then
      echo "  -> Rebuilding sycoca via nix run nixpkgs#kdePackages.kservice"
      if nix run nixpkgs#kdePackages.kservice --command kbuildsycoca6 --noincremental; then
        echo "     sycoca rebuild OK (nix run)"
      else
        echo "     sycoca rebuild failed (nix run)"
      fi
    else
      echo "  !! kbuildsycoca6 not found and nix not available, skipping rebuild"
    fi

    echo "  -> Restarting kactivitymanagerd"
    systemctl --user restart kactivitymanagerd.service || true
    if systemctl --user is-active kactivitymanagerd.service >/dev/null 2>&1; then
      echo "     kactivitymanagerd is active"
    else
      echo "     kactivitymanagerd failed to start"
    fi

    echo "  -> Restarting plasma-plasmashell"
    systemctl --user restart plasma-plasmashell.service || true
    if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
      echo "     plasmashell is active"
    else
      echo "     plasmashell failed to start"
    fi
  '
  rc=$?
  if [ "$rc" -eq 0 ]; then
    log "Done for $user"
  else
    log "Completed with errors for $user, rc=$rc"
  fi
}

main() {
  log "Scanning logged-in users"
  if command -v loginctl >/dev/null 2>&1; then
    loginctl list-users --no-legend 2>/dev/null | while read -r uid user _; do
      [ -n "$uid" ] && [ -n "$user" ] || continue
      refresh_plasma_for_user "$uid" "$user"
    done
  else
    log "loginctl not found, falling back to current user"
    refresh_plasma_for_user "$(id -u)" "$(id -un)"
  fi
  log "Plasma refresh complete"
}

main

