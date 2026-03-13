{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    session-desktop
  ];
}
