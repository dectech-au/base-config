{ config, pkgs, lib, ... }:

let
  host          = config.networking.hostName;
  rootPubKeyRaw = builtins.readFile "/root/.ssh/id_ed25519.pub";
  rootPubKey    = lib.strings.removeSuffix "\n" rootPubKeyRaw;
in
{
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # 1. PipeWire + KDE portal bits for KRDP
  services.pipewire = {
    enable            = true;
    audio.enable      = true;
    pulse.enable      = true;
    wireplumber.enable = true;
  };
  xdg.portal = {
    enable        = true;
    extraPortals  = [ kdePackages.xdg-desktop-portal-kde ];
  };

  # 2. Install KRDP
  environment.systemPackages = with pkgs; [ kdePackages.krdp ];

  # 3. User‐level systemd service that starts on login
  systemd.user.services.krdpserver = {
    Unit = {
      Description = "KRDP headless RDP server";
      After       = [ "graphical-session.target" ];
      Wants       = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = ''
        ${pkgs.kdePackages.krdp}/bin/krdpserver \
          -u ${host} \
          -p '${rootPubKey}' \
          --port 3389
      '';
      Restart   = "on-failure";
      Environment = "KRDP_NO_GUI=1";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
  # 4. Open RDP port
  networking.firewall.allowedTCPPorts = [ 3389 ];
}
