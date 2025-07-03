#~/.dotfiles/sys-modules/wordpress.nix
{ config, lib, pkgs, ... }:
{
  services.wordpress.sites."wordpress" = {
    # languages = [ pkgs.wordpressPackages.languages.en_US ];
    # settings = {
    #   WPLANG = "en_US";
    # };
  };
}
