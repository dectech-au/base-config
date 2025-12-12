{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python313Packages.tinytuya
  ];

  networking.allowedUDPPorts = [
    6666
    6667
    7000
  ];
}
