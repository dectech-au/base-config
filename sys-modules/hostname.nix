# sys-modules/dynamic-hostname.nix
{ config, pkgs, lib, ... }:

let
  setHost = pkgs.writeShellScript "derive-hostname" ''
    serial=$(tr -d ' ' </sys/class/dmi/id/product_serial 2>/dev/null || echo "")
    [ -z "$serial" ] && serial=$(cut -c1-8 /etc/machine-id)
    name="dectech-${serial: -6}"
    current=$(hostnamectl --static || true)

    if [ "$current" != "$name" ]; then
      echo "Setting hostname to $name"
      hostnamectl set-hostname "$name"
    fi
  '';
in {
  # Give a harmless default so NixOS boots even before the
  # service runs. It gets overwritten seconds later.
  networking.hostName = lib.mkDefault "placeholder";

  systemd.services.dynamic-hostname = {
    description = "Set hostname from serial/machine-id";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "network.target" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${setHost}";
    };
  };
}
