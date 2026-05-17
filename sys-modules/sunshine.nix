{ config, lib, pkgs, ... }:
  
  services.sunshine = {
    enable = true;
    openFirewall = true;
    #autoStart = true; 
    #capSysAdmin = true;
    settings.sunshine_name = "nixos-laptop";
    #package = pkgs.sunshine.override {
    #  cudaSupport = true;
    #  cudaPackages = pkgs.cudaPackages;
    #};
  };

#services.avahi.publish.enable = true;
#services.avahi.publish.userServices = true;
#hardware.uinput.enable = true;
#users.users.leo.extraGroups = [ "uinput" ];
