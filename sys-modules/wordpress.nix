#~/.dotfiles/sys-modules/wordpress.nix
{ config, lib, pkgs, ... }:
{
  services.wordpress.sites."localhost" = {
    virtualHost = {
      hostName = "localhost";
    };
    
    themes = {
      inherit (pkgs.wordpressPackages.themes)
        twentytwentythree;
    };
    
    plugins = {
      inherit (pkgs.wordpressPackages.plugins)
        antispam-bee
        opengraph;
    };
  };
  networking.hosts."127.0.0.1" = [ "wordpress.local" ];
}
