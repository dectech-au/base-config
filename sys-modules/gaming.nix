{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    rpcs3
  ];
}
