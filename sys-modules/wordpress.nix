#~/.dotfiles/sys-modules/wordpress.nix
{ config, lib, pkgs, ... }:
{
  services.wordpress.sites."localhost" = {
    languages = [ pkgs.wordpressPackages.languages.en_US ];
    settings = {
      WPLANG = "en_US";
    };
  };
}
