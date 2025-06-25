#~/.dotfiles/modules/thunderbird.nix
{ config, lib, pkgs, ... }:
{
  # programs.thunderbird = {
  #   enable = true;
  #   profiles.default = {
  #     isDefault = true;
  #     settings = {
  #       extensions.autoDisableScopes = "0";
  #     };
  #     # extensions = [
  #     #
  #     # ];
  #   };
  # };

  xdg.configFile = {
    "autostart/birdtray.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=birdtray
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Birdtray
      Comment=Thunderbird system tray integration
    '';

    "autostart/thunderbird.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=thunderbird --silent
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Thunderbird
      Comment=Start Thunderbird at login
    '';
  };
}
