#~/.dotfiles/sys-modules/wordpress.nix
{ config, lib, pkgs, ... }:
{
  services.wordpress.sites."wordpress" = {
    virtualHost = {
      hostName = "wordpress.local";
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
    # database = {
    #   name = "wordpress";
    #   user = "wp";
    #   password = "changeme";
    # };
    # admin = {
    #   user = "admin";
    #   password = "changeme";
    #   email = "admin@dectech.au";
    # };
  };

  networking.hosts."127.0.0.1" = [ "wordpress.local" ];
}
