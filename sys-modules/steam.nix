#~/.dotfiles/modules/steam.nix
{ config, lib, pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  systemd.user.services.steam-autostart = {
    enable = true;
    description = "Auto-start Steam on login";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.steam}/bin/steam";
      Restart = "on-failure";
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa.drivers
      mesa.vulkan-drivers
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa.drivers
      mesa.vulkan-drivers
    ];
  };

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    powerManagement.enable = true;
    powerManagement.finegrained = true;
  };

  environment.sessionVariables = {
    STEAM_RUNTIME = "1";
  };

  environment.systemPackages = with pkgs; [
    protonup-ng
    protonup-qt
    protonplus
    steamtinkerlaunch
  ];
}


    # Prevent Steam from mangling runtime
    STEAM_RUNTIME = "0";
    # Prefer system Vulkan drivers
    VK_ICD_FILENAMES = "${pkgs.mesa.drivers}/share/vulkan/icd.d/nvidia_icd.json";
    # For Steam controller driver support
    SDL_GAMECONTROLLERCONFIG = "/etc/SDLGameControllerDB.txt";
