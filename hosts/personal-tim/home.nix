#~/.dotfiles/hosts/personal-tim/home.nix
{ config, pkgs, MODULES, ... }:

{
  imports = [
    MODULES.dropbox
    MODULES.fastfetch
	  # MODULES.firefox # Moved to configuration.nix
    MODULES.fish
	  MODULES.kitty
    MODULES.librewolf
	  MODULES.git
    MODULES.start-menu_onlyoffice
    MODULES.start-menu_teams
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

