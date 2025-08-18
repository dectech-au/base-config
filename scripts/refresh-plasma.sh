#!/usr/bin/env bash
# script is useful for ensuring that the favourites menu in kickoff doesn't stagnate
# Refresh Plasma menus and favorites after an update
# Refresh Plasma menus and favorites after an update, with logging
# ----- Plasma refresh helpers -----
log() { echo "[plasma-refresh] $(date +'%F %T') $*"; }

refresh_now_for_user() {
  local uid="$1" user="$2" rt="/run/user/$1"
  log "Now-refresh for user=$user uid=$uid"

  if [ ! -S "$rt/bus" ]; then
    log "No DBus session at $rt/bus; cannot refresh now"
    return 1
  fi

  sudo -u "$user" env XDG_RUNTIME_DIR="$rt" DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" bash -lc '
    set -e
    echo "  -> Removing $HOME/.cache/ksycoca*"
    rm -f "$HOME/.cache/ksycoca"* || true

    if command -v kbuildsycoca6 >/dev/null 2>&1; then
      echo "  -> Rebuilding sycoca with kbuildsycoca6"
      kbuildsycoca6 --noincremental || true
    elif command -v nix >/dev/null 2>&1; then
      echo "  -> Rebuilding sycoca via nix run nixpkgs#kdePackages.kservice"
      nix run nixpkgs#kdePackages.kservice --command kbuildsycoca6 --noincremental || true
    else
      echo "  !! kbuildsycoca6 not found; skipped rebuild"
    fi

    # Restart what we can; safe if not running
    echo "  -> Restarting kactivitymanagerd"
    systemctl --user restart kactivitymanagerd.service || true
    echo "  -> Restarting plasma-plasmashell"
    systemctl --user restart plasma-plasmashell.service || true
  '
}

queue_autostart_for_user() {
  local uid="$1" user="$2"
  local home dir_bin dir_autostart
  home="$(getent passwd "$user" | cut -d: -f6)"
  dir_bin="$home/.local/bin"
  dir_autostart="$home/.config/autostart"

  log "Queue refresh at next Plasma login for $user"

  sudo -u "$user" bash -lc "
    set -e
    mkdir -p '$dir_bin' '$dir_autostart' '$home/.local/state'
    cat > '$dir_bin/plasma-refresh-once.sh' <<'EOF'
#!/usr/bin/env bash
set -e
logf=\"$HOME/.local/state/plasma-refresh.log\"
echo \"[plasma-refresh] \$(date +'%F %T') Autostart running\" | tee -a \"\$logf\"
rm -f \"\$HOME/.cache/ksycoca\"* || true
if command -v kbuildsycoca6 >/dev/null 2>&1; then
  echo \"  -> kbuildsycoca6\" | tee -a \"\$logf\"
  kbuildsycoca6 --noincremental || true
elif command -v nix >/dev/null 2>&1; then
  echo \"  -> nix run kbuildsycoca6\" | tee -a \"\$logf\"
  nix run nixpkgs#kdePackages.kservice --command kbuildsycoca6 --noincremental || true
else
  echo \"  !! no kbuildsycoca6 available\" | tee -a \"\$logf\"
fi
echo \"  -> restart kactivitymanagerd\" | tee -a \"\$logf\"
systemctl --user restart kactivitymanagerd.service || true
echo \"  -> restart plasmashell\" | tee -a \"\$logf\"
systemctl --user restart plasma-plasmashell.service || true
echo \"[plasma-refresh] \$(date +'%F %T') Autostart done\" | tee -a \"\$logf\"
rm -f \"\$HOME/.config/autostart/plasma-refresh-once.desktop\" || true
EOF
    chmod +x '$dir_bin/plasma-refresh-once.sh'

    cat > '$dir_autostart/plasma-refresh-once.desktop' <<'EOF'
[Desktop Entry]
Type=Application
Name=Plasma refresh one-shot
Comment=Rebuild KDE sycoca and restart activity manager and shell once after update
Exec=/bin/bash -lc "$HOME/.local/bin/plasma-refresh-once.sh"
OnlyShowIn=KDE;
X-KDE-autostart-phase=2
X-GNOME-Autostart-Delay=8
EOF
  "
}

refresh_plasma_for_user() {
  local uid="$1" user="$2" rt="/run/user/$1"
  log "Start for user=$user uid=$uid"

  # If a Plasma session is up, do it now; else queue for next login
  if [ -S "$rt/bus" ]; then
    if pgrep -u "$uid" -x plasmashell >/dev/null 2>&1 || pgrep -u "$uid" -x kactivitymanagerd >/dev/null 2>&1; then
      refresh_now_for_user "$uid" "$user" && { log "Done for $user"; return; }
      log "Now-refresh failed for $user; will queue autostart"
      queue_autostart_for_user "$uid" "$user"
    else
      log "Session bus exists but shell not running; queue autostart for $user"
      queue_autostart_for_user "$uid" "$user"
    fi
  else
    log "No user bus; user is not logged in graphically; queue autostart for $user"
    queue_autostart_for_user "$uid" "$user"
  fi
}

run_plasma_refresh() {
  log "Scanning logged-in users"
  if command -v loginctl >/dev/null 2>&1; then
    loginctl list-users --no-legend 2>/dev/null | while read -r uid user _; do
      [ -n "$uid" ] && [ -n "$user" ] || continue
      refresh_plasma_for_user "$uid" "$user"
    done
  else
    log "loginctl not found; falling back to current user"
    refresh_plasma_for_user "$(id -u)" "$(id -un)"
  fi
  log "Plasma refresh complete"
}
# ----- end helpers -----

# Call it from your update flow
run_plasma_refresh
