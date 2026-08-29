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
      nvidiaPersistenced = false;

      open = false;
      powerManagement = {
        enable = true;
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


  # The missing piece — Intel VAAPI userspace
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver       # iHD — preferred for Gen 8+ (UHD 630 = Gen 9.5)
      intel-vaapi-driver               # i965 — fallback older driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  # Keep modesetting on — it's what put nvidia-drm into the right mode
  hardware.nvidia.modesetting.enable = true;
