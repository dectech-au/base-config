#~/.dotfiles/hosts/personal-tim/personalisation/wallpaper-service.nix
{ config, lib, pkgs, ... }:
{
  home.activation.setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /run/current-system/sw/bin/plasma-apply-wallpaperimage /home/dectec/.dotfiles/hosts/personal-tim/personalisation/wallpaper.png
  '';
}
