{ config, lib, pkgs, ... }:
{
  programs.plasma = {
    enable = true;

    workspace = {
      lookAndFeel = "org.kde.breeze.desktop";
      iconTheme   = "Papirus";
      wallpaper   = "../personalisation/wallpapers/dectech-no-label.png";
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
