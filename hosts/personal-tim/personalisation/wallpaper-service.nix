#~/.dotfiles/hosts/personal-tim/personalisation/wallpaper-service.nix
{ config, lib, pkgs, ... }:
{
  systemd.user.services.set-wallpaper = {
    description = "Set KDE Plasma Wallpaper";
    serviceConfig.ExecStart = [ "/run/current-system/sw/bin/plasma-apply-wallpaperimage /home/dectec/.dotfiles/hosts/personal-tim/persionalisation/wallpaper.png" ];
    wantedBy = [ "graphical-session.target" ];
  };
}
