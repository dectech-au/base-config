#!/usr/bin/env bash
# script is useful for ensuring that the favourites menu in kickoff doesn't stagnate

_refresh_user_now() {
  local uid="$1" user="$2" rt="/run/user/$1"
  log "Refreshing for user=$user uid=$uid"

  # Rebuild sycoca as the target user, with sane XDG env
  sudo -u "$user" bash -lc '
    set -e
    echo "  -> Clearing $HOME/.cache/ksycoca*"
    rm -f "$HOME/.cache/ksycoca"* || true

    # Ensure KDE sees NixOS menu and desktop entries
    export XDG_CONFIG_DIRS="/etc/xdg:/etc/profiles/per-user/$USER/etc/xdg:/run/current-system/sw/etc/xdg"
    export XDG_DATA_DIRS="/etc/profiles/per-user/$USER/share:/run/current-system/sw/share:/usr/local/share:/usr/share"

    if [ -e "/etc/xdg/menus/applications.menu" ] || [ -e "/run/current-system/sw/etc/xdg/menus/applications.menu" ]; then
      echo "  -> Menu file present"
    else
      echo "  !! Menu file not found under $XDG_CONFIG_DIRS; proceeding anyway"
    fi

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

  # If a session bus exists, try gentle restarts; else just finish
  if [ -S "$rt/bus" ]; then
    log "Attempting user service restarts for $user"
    sudo -u "$user" env DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" bash -lc '
      # Plasmashell via systemd user unit
      echo "  -> systemctl --user try-restart plasma-plasmashell.service"
      systemctl --user try-restart plasma-plasmashell.service || true

      # kactivitymanagerd: try systemd, then fall back to kill, then start if missing
      echo "  -> systemctl --user try-restart kactivitymanagerd.service"
      if ! systemctl --user try-restart kactivitymanagerd.service >/dev/null 2>&1; then
        if pgrep -x kactivitymanagerd >/dev/null 2>&1; then
          echo "     unit missing; killing running kactivitymanagerd"
          pkill -x kactivitymanagerd || true
        else
          echo "     unit missing; kactivitymanagerd not running"
        fi
        if command -v kactivitymanagerd >/dev/null 2>&1; then
          echo "  -> starting kactivitymanagerd"
          nohup kactivitymanagerd >/dev/null 2>&1 &
        fi
      fi

      echo "  -> kactivitymanagerd status:"
      pgrep -x kactivitymanagerd >/dev/null && echo "     running" || echo "     not running"

      echo "  -> plasmashell status:"
      systemctl --user is-active plasma-plasmashell.service >/dev/null && echo "     active" || echo "     inactive"
    '
  else
    log "No DBus session for $user; skipped restarts, cache already rebuilt"
  fi

  log "Done for $user"
}
