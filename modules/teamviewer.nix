{ config, lib, pkgs, ... }:
{
  services.teamviewer.enable = true;

  networking.firewall = {
    enable = true;
    allowTCPPorts = [5938];
  };
}
