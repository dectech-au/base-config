#~/.dotfiles/sys-modules/nvidia.nix
{ config, lib, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ]; # Gates the hardware.nvidia block below. required even on Wayland.

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
    
  hardware.nvidia = {
    
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;

    powerManagement = {
      enable = true;
      finegrained = false; # Runtime D3. Revert to false first if suspend/resume misbehaves.
    };

    prime.offload = {
      enable = false;
      enableOffloadCmd = false;
    };

    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

  };
}
