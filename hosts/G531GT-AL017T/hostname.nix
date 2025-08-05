# /etc/nixos/sys-modules/dynamic-hostname.nix
{ config, lib, pkgs, ... }:

let
  fixHostname = pkgs.writeShellScript "fix-hostname" ''
    #!/usr/bin/env bash

    # 1. read hardware serial, fall back to machine-id
    if [[ -r /sys/class/dmi/id/product_serial ]]; then
      raw=$(tr -d ' \t\n' < /sys/class/dmi/id/product_serial)
    else
      raw=$(cut -c1-32 /etc/machine-id)
    fi

    # 2. last six characters
    serial6=$(printf '%s' "$raw" | tail -c 6)

    # 3. compose final hostname
    host="dectech-${serial6}"

    # 4. apply only if different
    current=$(hostnamectl --static 2>/dev/null || true)
    if [[ "$current" != "$host" ]]; then
      echo "Setting hostname to $host"
      hostnamectl set-hostname "$host"
    fi
  '';
in
{
  # harmless placeholder that lets evaluation succeed
  networking.hostName = lib.mkDefault "placeholder";

  ### run script during activation (every nixos-rebuild switch)
  system.activationScripts.dynamic-hostname.text = ''
    ${fixHostname}
  '';
}
