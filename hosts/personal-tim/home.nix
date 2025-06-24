#~/.dotfiles/hosts/personal-tim/home.nix
{ config, pkgs, HOME-MODULES, ... }:

{
  imports = [
    ../../modules/dropbox.nix
    ../../modules/fastfetch.nix
	  #../../modules/firefox.nix # Moved to configuration.nix
    ../../modules/fish.nix
	  ../../modules/git.nix
    ../../modules/kdeconnect.nix
	  ../../modules/kitty.nix
    ../../modules/librewolf.nix
    ../../modules/onlyoffice.nix
    #../../modules/remotemouse.nix
    ../../modules/thunderbird.nix
    ../../modules/vscode.nix
    ../../modules/start-menu/onlyoffice.nix
    ../../modules/start-menu/teams.nix
    ../../modules/start-menu/windows.nix
    ./personalisation/wallpaper.nix
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

