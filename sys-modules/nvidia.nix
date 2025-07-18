#~/.dotfiles/sys-modules/nvidia.nix
{ config, lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.gamemode.enable = true;

  environment.sessionVariables = {
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_GSYNC_ALLOWED          = "1";
    __GL_VRR_ALLOWED            = "1";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;
    
    nvidia = {
      modesetting.enable = true;
      open = false;
      powerManagement = {
        enable = true;
        nvidiaPersistenced = true;
        finegrained = false;
      };

      nvidiaSettings = true;


      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };
}
