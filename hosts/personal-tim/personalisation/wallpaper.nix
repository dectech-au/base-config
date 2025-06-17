#~/.dotfiles/hosts/personal-tim/personalisation/wallpaper.nix
{ config, lib, pkgs, ... }:
{
  home.file.".config/plasma-org.kde.plasma.desktop-appletsrc".text = ''
    [Containments][1][Wallpaper][org.kde.image][General]
    Image=file:///home/dectec/.dotfiles/hosts/personal-tim/personalisation/wallpaper.jpg
  '';
}
