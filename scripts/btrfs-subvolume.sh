#!/usr/bin/env bash
set -euo pipefail

sudo mkdir -p /mnt/btrfs-root
sudo mount -o subvolid=0 /dev/disk/by-partlabel/dectech-enterprise /mnt/btrfs-root

read -rp "Type the subvolume path relative to /mnt/btrfs-root/ (e.g. honkai-shared): " rest
cmd=(sudo btrfs subvolume create "/mnt/btrfs-root/$rest")
echo "Running: ${cmd[*]}"
"${cmd[@]}"

sudo umount /mnt/btrfs-root

echo "Add the subvolume to /etc/nixos/hardware-configuration.nix"
