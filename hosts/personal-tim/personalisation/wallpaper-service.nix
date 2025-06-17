#~/.dotfiles/hosts/personal-tim/personalisation/wallpaper-service.nix
{ config, lib, pkgs, ... }:
{
  systemd.services.set-wallpaper = {
    description = "Set KDE Plasma Wallpaper";
    #serviceConfig.ExecStart = [ "/run/current-system/sw/bin/plasma-apply-wallpaperimage /home/dectec/.dotfiles/hosts/personal-tim/persionalisation/wallpaper.png" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "graphical.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.plasma-workspace}/bin/plasma-apply-wallpaperimage /home/dectec/.dotfiles/hosts/personal-tim/personalisation/wallpaper.png";
    };
  };
}
