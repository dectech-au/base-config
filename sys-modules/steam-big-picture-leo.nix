{ config, lib, pkgs, ... }:
{
  home-manager.users.leo.systemd.user.services.steam-bigpicture = {
    Unit = {
      Description = "Autostart Steam in Big Picture mode once XWayland is ready";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.writeShellScript "wait-for-xwayland" ''
        until ${pkgs.xorg.xset}/bin/xset q >/dev/null 2>&1; do
          sleep 0.5
        done
      ''}";
      ExecStart = "${pkgs.steam}/bin/steam -bigpicture %U";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
