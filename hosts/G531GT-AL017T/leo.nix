{ config, lib, pkgs, ... }:
{

  home-manager.users.leo = {
    home.stateVersion = "26.05";  

    dconf.settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [ 
        "no-overview@fthx"
      ];
    };
  };


}
