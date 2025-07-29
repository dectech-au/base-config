{ config, lib, pkgs, ... }:

let
  myWallpaper = pkgs.runCommand "my-wallpaper" { } ''
    install -Dm444 ${./Pictures/untitled.jpg} $out/share/wallpapers/untitled.jpg
  '';
in
{
  programs.plasma = {
    enable = true;

    workspace = {
      lookAndFeel = "org.kde.breeze.desktop";
      iconTheme   = "Papirus";
      wallpaper   = "${myWallpaper}/share/wallpapers/untitled.jpg";
    };

    hotkeys.commands."launch-kitty" = {
      name    = "Launch Kitty";
      key     = "Ctrl+Alt+T";
      command = "kitty";
    };

    panels = [{
      location = "bottom";
      hiding   = "none";
    }];

    configFile = {
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;
      kwinrc."org.kde.kdecoration2".ButtonsOnLeft       = "SF";
      kwinrc.Desktops.Number.value                      = 2;
    };
  };
}
