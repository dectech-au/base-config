{ config, lib, pkgs, ... }:
{
  services.teamviewer.enable = true;

  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [5938];
  };
}
