{ config, pkgs, ... }:

{
  imports = [
	./modules/fish.nix
	./modules/kitty.nix
	./modules/git.nix
  ];

  home.username = "dectec";
  home.homeDirectory = "/home/dectec";
  home.stateVersion = "25.05"; # Do not change this after initial setup

  programs.git = {
    enable = true;
    userName = "DecTec";
    userEmail = "zozano@protonmail.com";
  };

  # home.file.".config/kitty/kitty.conf".text = "source/config/kitty/kitty.conf";
}

