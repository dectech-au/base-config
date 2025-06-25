{ config, lib, pkgs, ... }:
{
  networking.firewall = {
    enable = true;
    allowedUDPPorts = lib.range 1714 1764;
  };

  environment.systemPackages = with pkgs; [
    scrcpy
  ];
}
