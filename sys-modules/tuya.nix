{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python313Packages.tinytuya
  ];

  networking.firewall.allowedUDPPorts = [
    6666
    6667
    7000
  ];
}
