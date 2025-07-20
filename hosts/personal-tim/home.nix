#/etc/nixos/hosts/personal-tim/home.nix
{ config, pkgs, HOME-MODULES, ... }:

{
  imports = [
	../../home-modules/dropbox.nix
	../../home-modules/fastfetch.nix
	#../../home-modules/firefox.nix # Moved to configuration.nix
	../../home-modules/fish.nix
	../../home-modules/git.nix
	../../home-modules/kdeconnect.nix
	../../home-modules/kitty.nix
	../../home-modules/librewolf.nix
	#../../home-modules/onlyoffice.nix
	#../../home-modules/papirus-theme.nix
	#../../home-modules/remotemouse.nix
	../../home-modules/thunderbird.nix
	../../home-modules/thunderbird-theme.nix
	../../home-modules/vscode.nix
	../../home-modules/start-menu/onlyoffice.nix
	../../home-modules/start-menu/teams.nix
	../../home-modules/start-menu/windows.nix
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

