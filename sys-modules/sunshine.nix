{ config, lib, pkgs, ... }:

  services.sunshine = {
    enable = true;
    autoStart = true;       # starts on user login (needs a graphical session)
    settings.sunshine_name = "nixos-laptop";
    capSysAdmin = true;     # required for KMS capture on Wayland
    openFirewall = true;    # opens 47984/47989/47990/48010 TCP, 47998-48000/48002 UDP
  };

  # uinput is required for the virtual gamepad/keyboard/mouse
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", MODE="0660"
  '';

  # mDNS so Moonlight clients on the LAN auto-discover the host
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
    openFirewall = true;
  };

  # NVENC needs the NVIDIA userland; 32-bit for Steam/Proton titles
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Moonlight client (optional — handy for testing from another host)
  # environment.systemPackages = [ pkgs.moonlight-qt ];
}
