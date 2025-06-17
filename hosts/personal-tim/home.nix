#~/.dotfiles/hosts/personal-tim/home.nix
{ config, pkgs, HOME-MODULES, ... }:

{
  imports = [
    HOME-MODULES.dropbox
    HOME-MODULES.fastfetch
	  # HOME-MODULES.firefox # Moved to configuration.nix
    HOME-MODULES.fish
	  HOME-MODULES.kitty
    HOME-MODULES.librewolf
	  HOME-MODULES.git
    HOME-MODULES.start-menu_onlyoffice
    HOME-MODULES.start-menu_teams
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

