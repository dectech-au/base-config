#~/.dotfiles/sys-modules/wordpress.nix
{ config, lib, pkgs, ... }:
{
  services.wordpress.sites."localhost" = {
    languages = [ pkgs.wordpressPackages.languages.en_AU ];
    settings = {
      WPLANG = "en_AU";
    };
  };
}
