#!/usr/bin/env bash
# labels.sh – relabel the three partitions on the disk that actually holds "/"
#   <disk>1 → boot-ssd
#   <disk>2 → dectech-enterprise-ssd
#   <disk>3 → swap-ssd
# Extremely verbose for debugging.

set -euo pipefail

log()  { printf '\e[1;32m[+] %s\e[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
err()  { printf '\e[1;31m    ! %s\e[0m\n' "$*" >&2; }

[[ $EUID -eq 0 ]] || { err "Run as root"; exit 1; }

###############################################################################
# 1. Identify root disk
###############################################################################
log "Detecting root partition"
root_part="$(findmnt -n -o SOURCE /)"
info "/ is mounted from: $root_part"

# If Btrfs, SOURCE looks like  /dev/disk/by-uuid/XXXX[/@]
root_part="${root_part%%\[*}"         # strip [subvol] suffix if present
info "Stripped subvol → $root_part"

root_part="$(readlink -f "$root_part")"
info "Resolved symlinks → $root_part"

# unwrap dm-crypt / LVM
if [[ $root_part == /dev/mapper/* || $root_part == /dev/dm-* ]]; then
  parent="/dev/$(lsblk -no PKNAME "$root_part")"
  info "Mapper detected; parent partition: $parent"
  root_part="$parent"
fi

case "$root_part" in
  /dev/nvme*n[0-9]p[0-9]*) disk="${root_part%%p[0-9]*}" ;;
  /dev/*[a-z][0-9]*)        disk="${root_part%%[0-9]*}" ;;
  *) err "Cannot parse parent disk from $root_part"; exit 1 ;;
esac
info "Root disk determined: $disk"

###############################################################################
# 2. Relabel helper
###############################################################################
relabel() {
  local part="$1" want="$2"

  [[ -b $part ]] || { err "$part does not exist – skipping"; return; }

  local idx cur
  # Newer util-linux: PARTNUMBER column works
  idx=$(lsblk -no PARTNUMBER "$part" 2>/dev/null || true)
  cur=$(blkid -s PARTLABEL -o value "$part" || true)

  info "Partition $part idx='${idx:-?}' current='${cur:-<none>}' target='$want'"

  [[ $cur == "$want" ]] && { info " ↳ already correct"; return; }

  # -------- fallback: derive idx with regex ---------------------------------
  if [[ -z $idx ]]; then
    if [[ $part =~ ^/dev/nvme[0-9]+n[0-9]+p([0-9]+)$ ]]; then
      idx="${BASH_REMATCH[1]}"
    elif [[ $part =~ ^/dev/[a-z]+([0-9]+)$ ]]; then
      idx="${BASH_REMATCH[1]}"
    fi
    [[ -z $idx ]] && { err "Cannot determine partition number for $part"; return; }
    info " ↳ fallback idx=$idx"
  fi
  # --------------------------------------------------------------------------

  info " ↳ sgdisk -c ${idx}:$want $disk"
  if sgdisk -c "${idx}:${want}" "$disk"; then
    info " ↳ relabel OK"
  else
    err "sgdisk failed for $part"
  fi
}
###############################################################################
# 3. Relabel partitions 1–3 on the root disk
###############################################################################
log "Relabelling GPT labels on $disk"
set +e
relabel "${disk}1" boot-ssd
relabel "${disk}2" dectech-enterprise-ssd
relabel "${disk}3" swap-ssd
set -e

###############################################################################
# 4. Verify
###############################################################################
log "Verifying labels"

verify() {
  local part="$1" want="$2"
  [[ -b $part ]] || { err "$part missing"; return 1; }
  local have
  have="$(blkid -s PARTLABEL -o value "$part" || true)"
  if [[ $have != "$want" ]]; then
    err "$part label='$have' (expected '$want')"
    return 1
  fi
  info "$part OK (label='$have')"
}

bad=0
verify "${disk}1" boot-ssd               || bad=1
verify "${disk}2" dectech-enterprise-ssd || bad=1
verify "${disk}3" swap-ssd               || bad=1

if [[ $bad -eq 0 ]]; then
  log "✓ all labels correct"
else
  err "Label verification FAILED"
  exit 1
fi

