#~/.dotfiles/hosts/personal-tim/home.nix
{ config, pkgs, MODULES, ... }:

{
  imports = [
    ( MODULES + "/dropbox.nix" )
    ( MODULES + "/fastfetch.nix" )
	  # ( MODULES + "/firefox.nix" ) # Moved to configuration.nix
    ( MODULES + "/fish.nix" )
	  ( MODULES + "/kitty.nix" )
    ( MODULES + "/librewolf.nix" )
	  ( MODULES + "/git.nix" )
    ( MODULES + "/start-menu/start-onlyoffice.nix" )
    ( MODULES + "/start-menu/teams.nix" )
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

