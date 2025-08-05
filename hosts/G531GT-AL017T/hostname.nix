{ config, lib, pkgs, ... }:
let
  hostnameScript = pkgs.writeTextFile {
    name = "derive-hostname";
    destination = "/bin/derive-hostname";
    executable = true;
    text = ''
      #!/usr/bin/env bash
      if [[ -r /sys/class/dmi/id/product_serial ]]; then
        raw=$(tr -d ' \t\n' < /sys/class/dmi/id/product_serial)
      else
        raw=$(cut -c1-32 /etc/machine-id)
      fi
      serial6="${raw: -6}"
      name="ASUS-G531GT-AL017T-${serial6}"

      current=$(hostnamectl --static 2>/dev/null || true)
      [[ "$current" != "$name" ]] && hostnamectl set-hostname "$name"
    '';
  };
in {
  networking.hostName = lib.mkDefault "placeholder";

  systemd.services.dynamic-hostname = {
    description  = "Set hostname from hardware serial";
    wantedBy     = [ "multi-user.target" ];
    after        = [ "systemd-user-sessions.service" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${hostnameScript}/bin/derive-hostname";
    };
  };
}
