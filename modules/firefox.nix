#~/.dotfiles/modules/firefox.nix
{ config, lib, pkgs, ... }:
{
	programs.firefox = {
    enable = true;
    profiles.default.extensions.packages = [
      "uBlock0@raymondhill.net"
      "https-everywhere@eff.org"
      "addon@darkreader.org"
    ];
  };
}
