{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python311Packages.whisper
  ];
)
