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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    
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
