#~/.dotfiles/sys-modules/nvidia.nix
{ config, lib, pkgs, ... }:
{
  environment.sessionVariables = {
    __GL_THREADED_OPTIMIZATIONS = "1";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
    
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaPersistenced = false;
    nvidiaSettings = true;
    open = false;

    powerManagement = {
      enable = true;
      finegrained = true;
    };

    prime.offload = {
      enable = true;
      enableOffloadCmd = true;
    };
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
