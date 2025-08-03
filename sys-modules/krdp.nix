{ config, pkgs, lib, ... }:

let
  host          = config.networking.hostName;
  rootPubKeyRaw = builtins.readFile "/root/.ssh/id_ed25519.pub";
  rootPubKey    = lib.strings.removeSuffix "\n" rootPubKeyRaw;
in
{
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
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
  };

  # 2. Install KRDP
  environment.systemPackages = with pkgs; [ 
    kdePackages.krdp
    kdePackages.xdg-desktop-portal-kde
  ];

  systemd.user.services.krdpserver = {
    enable      = true;
    description = "KRDP headless RDP server";
    wants       = [ "graphical-session.target" ];
    after       = [ "graphical-session.target" ];
    wantedBy    = [ "default.target" ];

    serviceConfig = {
      # shell-wrap so $(cat ...) happens at runtime
      ExecStart = ''
        /bin/sh -c '${pkgs.kdePackages.krdp}/bin/krdpserver \
          -u ${host} \
          -p "$(cat /root/.ssh/id_ed25519.pub)" \
          --port 3389'
      '';
      Restart     = "on-failure";
      Environment = [ "KRDP_NO_GUI=1" ];
    };
  };

  # 4. Open RDP port
  networking.firewall.allowedTCPPorts = [ 3389 ];
}
