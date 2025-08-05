{ config, lib, pkgs, ... }:

let
  # One-shot shell script that runs *at boot*, not at eval
  setHost = pkgs.writeShellScript "derive-hostname" ''
    # Pick serial first; fall back to machine-id
    if [[ -r /sys/class/dmi/id/product_serial ]]; then
      raw=$(tr -d ' \t\n' < /sys/class/dmi/id/product_serial)
    else
      raw=$(cut -c1-32 /etc/machine-id)
    fi

    serial6=${raw: -6}
    name="ASUS-G531GT-AL017T-${serial6}"

    current=$(hostnamectl --static 2>/dev/null || true)

    if [[ "$current" != "$name" ]]; then
      echo "Setting hostname to $name"
      hostnamectl set-hostname "$name"
    fi
  '';
in {
  # Compile-time placeholder so evaluation succeeds
  networking.hostName = lib.mkDefault "placeholder";

  systemd.services.dynamic-hostname = {
    description = "Derive hostname from hardware serial";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "systemd-user-sessions.service" ];
    serviceConfig = {
      Type       = "oneshot";
      ExecStart  = "${setHost}";
      RemainAfterExit = false;
    };
  };
}
