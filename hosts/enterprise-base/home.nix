{ config, pkgs, ... }:

{
  imports = [
  ../../home-modules/dropbox.nix
  ../../home-modules/fastfetch.nix
  #../../home-modules/firefox.nix # Moved to configuration.nix
  ../../home-modules/fish.nix
  ../../home-modules/kitty.nix
  ../../home-modules/librewolf.nix
  ../../home-modules/git.nix
  #../../home-modules/start-menu/start-onlyoffice.nix
  #../../home-modules/start-menu/teams.nix
  ];

  home.username = "dectec";
  home.homeDirectory = "/home/dectec";
  home.stateVersion = "25.05"; # Do not change this after initial setup

  programs.git = {
    enable = true;
    userName = "DecTec";
    userEmail = "zozano@protonmail.com";
  };

  # home.file.".local/share/applications/teams.desktop".text = ''
  #   test
  # '';
}

