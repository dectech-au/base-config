{ config, lib, pkgs, ... }:
{
  programs.plasma = {
    enable = true;
    
    workspace = {
      # clickItemTo = "open"; # If you liked the click-to-open default from plasma 5
      lookAndFeel = "org.kde.breeze.desktop";
      # cursor = {
        # theme = "Bibata-Modern-Ice";
        # size = 32;
      # };
      iconTheme = "Papirus";
      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
    };

    hotkeys.commands."launch-kitty" = {
      name = "Launch Kity";
      key = "Ctrl+Alt+T";
      command = "kitty";
    };

    fonts = {
      general = {
        family = "Hack";
        pointSize = 10;
      };
    };

    panels = [{ 
      location = "bottom";
      hiding = "none";
    }];

    configFile = {
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;
      kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "SF";
      kwinrc.Desktops.Number = {
        value = 2;
        # Forces kde to not change this value (even through the settings app).
        immutable = false;
      };
    };

  };
}
