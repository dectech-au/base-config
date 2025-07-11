#~/.dotfiles/sys-modules/qt.nix
{ config, lib, pkgs, ... }:
{
  qt = {
    enable = true;
    platformTheme = "gnome";
    style.name = "papirus";
  };


}
