#~/.dotfiles/hosts/personal-tim/personalisation/wallpaper-service.nix
{ config, lib, pkgs, ... }:
{
  home.activation.setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.plasma-workspace}/bin/plasma-apply-wallpaperimage /home/dectec/.dotfiles/hosts/personal-tim/personalisation/wallpaper.png
  '';
}
