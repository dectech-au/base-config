#~/.dotfiles/sys-modules/wordpress.nix
{ config, lib, pkgs, ... }:
{
  services.wordpress.sites."wordpress" = {
    virtualHost = {
      hostName = "wordpress.local";
      #listen = [{ ip = "127.0.0.1"; port = 8080; }];
    };
    database = {
      name = "wordpress";
      user = "wp";
      password = "changeme";
    };
    admin = {
      user = "admin";
      password = "changeme";
      email = "admin@dectech.au";
    };
  };
}
