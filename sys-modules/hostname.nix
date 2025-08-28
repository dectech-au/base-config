{ config, pkgs, lib, ... }:

let
  setHost = pkgs.writeShellScript "derive-hostname" ''
    set -eu
    serial=""
    if [ -r /sys/class/dmi/id/product_serial ]; then
      serial=$(tr -d ' \n' </sys/class/dmi/id/product_serial || true)
    fi
    if [ -z "$serial" ] && [ -r /etc/machine-id ]; then
      serial=$(cut -c1-8 /etc/machine-id || true)
    fi

    short=$(printf %s "$serial" | tail -c 6)
    name="dectech-$short"
    current=$(hostnamectl --static 2>/dev/null || true)

    if [ "$current" != "$name" ]; then
      echo "Setting hostname to $name"
      hostnamectl set-hostname "$name"
    fi
  '';
in {
  networking.hostName = lib.mkDefault "placeholder";  # valid option, documented by MyNixOS. :contentReference[oaicite:0]{index=0}

  systemd.services.dynamic-hostname = {
    description = "Set hostname from serial/machine-id";
    wantedBy    = [ "multi-user.target" ];            # documented systemd.services.<name>.wantedBy. :contentReference[oaicite:1]{index=1}
    after       = [ "network.target" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${setHost}";
      Restart   = lib.mkForce "no";                   # service options go under serviceConfig. :contentReference[oaicite:2]{index=2}
    };
  };
}
