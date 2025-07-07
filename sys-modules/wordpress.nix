#~/.dotfiles/sys-modules/wordpress.nix
{ config, lib, pkgs, ... }:
{
  services.wordpress.sites."wordpress.localhost" = {
    virtualHost = {
      hostName = "wordpress.localhost";
    };
    
    themes = {
      inherit (pkgs.wordpressPackages.themes)
        #geist
        proton
        twentytwenty
        twentynineteen
        twentytwentyone
        twentytwentytwo
        twentytwentythree
        twentytwentyfour
        twentytwentyfive;
    };
    
    plugins = {
      inherit (pkgs.wordpressPackages.plugins)
        antispam-bee
        opengraph;
    };
  };
  networking.hosts."127.0.0.1" = [ "wordpress.local" ];
}
