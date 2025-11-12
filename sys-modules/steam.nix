#~/.dotfiles/modules/steam.nix
{ config, lib, pkgs, ... }:
{
  programs.steam.enable = true;

  systemd.user.services.steam-autostart = {
    enable = true;
    description = "Auto-start Steam on login";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.steam}/bin/steam";
      Restart = "on-failure";
    };
  };

  environment.systemPackages = with pkgs; [
    protonup-ng
    protonup-qt
    protonplus
    steamtinkerlaunch
  ];
}
