{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    # NVENC can stay in the build, but use vaapi since the display is on i915
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };

    settings = {
      encoder = "vaapi";
      adapter_name = "/dev/dri/renderD129";  # Intel render node (00:02.0)
    };

    applications = {
      env.PATH = "$(PATH):$(HOME)/.local/bin";
      apps = [
        { name = "Desktop"; image-path = "desktop.png"; }
        {
          name = "Steam Big Picture";
          detached = [ "setsid steam steam://open/bigpicture" ];
          prep-cmd = [ { do = ""; undo = "setsid steam steam://close/bigpicture"; } ];
          image-path = "steam.png";
        }
      ];
    };
  };

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

  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", MODE="0660"
  '';

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = { enable = true; addresses = true; userServices = true; };
    openFirewall = true;
  };
}
