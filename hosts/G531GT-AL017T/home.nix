#/etc/nixos/hosts/G531GT-AL017T/home.nix
{ config, pkgs, HOME-MODULES, ... }:
{
  imports = [
		../../home-modules/dropbox.nix
		#../../home-modules/emacs.nix
		../../home-modules/fastfetch.nix
		#../../home-modules/firefox.nix # Moved to configuration.nix
		../../home-modules/fish-G531GT-AL017T.nix
		../../home-modules/git.nix
		../../home-modules/kdeconnect.nix
		../../home-modules/kitty.nix
		../../home-modules/librewolf.nix
		#../../home-modules/lutris.nix
		#../../home-modules/onlyoffice.nix
		#../../home-modules/papirus-theme.nix
		../../home-modules/plasma-manager.nix
		#../../home-modules/remotemouse.nix
		../../home-modules/tabula-java.nix
		../../home-modules/thunderbird.nix
		#../../home-modules/thunderbird-theme.nix
		../../home-modules/vscode.nix
		../../home-modules/yt-dlp.nix
		../../home-modules/signal_overlay.nix
		../../home-modules/scripts/open-journal.nix
		#../../home-modules/start-menu/onlyoffice.nix
		../../home-modules/start-menu/teams.nix
		../../home-modules/start-menu/update.nix
		../../home-modules/start-menu/windows.nix
		../../home-modules/syncthing.nix
		#./personalisation/wallpaper.nix
		../../custom-modules/hastings-preschool/0-imports.nix
  ];

  home.username = "dectec";
  home.homeDirectory = "/home/dectec";
  home.stateVersion = "25.05"; # Do not change this after initial setup

  # home.file.".local/share/applications/teams.desktop".text = ''
  #   test
  # '';
}
