# sys-modules/dynamic-hostname.nix
{ config, lib, pkgs, ... }:

let
  hostnameScript = pkgs.writeTextFile {
    name        = "derive-hostname";
    destination = "/bin/derive-hostname";
    executable  = true;
    text = ''
      #!/usr/bin/env bash

      # get hardware serial or fall back to machine-id
      if [[ -r /sys/class/dmi/id/product_serial ]]; then
        raw=$(tr -d ' \t\n' < /sys/class/dmi/id/product_serial)
      else
        raw=$(cut -c1-32 /etc/machine-id)
      fi

      # last six characters, no brace expansion
      serial6=$(printf '%s' "$raw" | tail -c 6)

      # assemble hostname
      name="ASUS-G531GT-AL017T-$serial6"

      current=$(hostnamectl --static 2>/dev/null || true)
      if [[ "$current" != "$name" ]]; then
        echo "Setting hostname to $name"
        hostnamectl set-hostname "$name"
      fi
    '';
  };
in
{
  # placeholder so evaluation succeeds
  networking.hostName = lib.mkDefault "placeholder";

  systemd.services.dynamic-hostname = {
    description   = "Set hostname from hardware serial";
    wantedBy      = [ "multi-user.target" ];
    after         = [ "systemd-user-sessions.service" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${hostnameScript}/bin/derive-hostname";
    };
  };
}

