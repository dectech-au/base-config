# xfce.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
  };

  # XFCE extras
  environment.systemPackages = with pkgs; [
    xfce4-screenshooter
  ];
}
