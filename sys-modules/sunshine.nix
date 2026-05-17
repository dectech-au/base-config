# ~/.dotfiles/modules/sunshine.nix
{ config, lib, pkgs, ... }:

{
  # CUDA is unfree; required to build sunshine with NVENC
  nixpkgs.config.allowUnfree = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    # Build sunshine with NVENC support
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };

    # Skip vaapi/software probing — go straight to nvenc on the dGPU
    settings = {
      encoder = "nvenc";
      # Optional: useful when there are multiple display outputs
      # output_name = "0";
    };

    # Declarative apps — replaces ~/.config/sunshine/apps.json
    # Note: your existing apps.json uses `xrandr` which won't work on KDE Wayland.
    # Use kscreen-doctor instead, or drop the Low Res preset.
    applications = {
      env = {
        PATH = "$(PATH):$(HOME)/.local/bin";
      };
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
        {
          name = "Steam Big Picture";
          detached = [ "setsid steam steam://open/bigpicture" ];
          prep-cmd = [
            { do = ""; undo = "setsid steam steam://close/bigpicture"; }
          ];
          image-path = "steam.png";
        }
      ];
    };
  };

  # NVIDIA must have modesetting on for KMS capture under Wayland
  hardware.nvidia.modesetting.enable = true;

  # uinput for virtual gamepad/keyboard/mouse from the Moonlight client
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", MODE="0660"
  '';

  # mDNS discovery for Moonlight clients on the LAN
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = { enable = true; addresses = true; userServices = true; };
    openFirewall = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
