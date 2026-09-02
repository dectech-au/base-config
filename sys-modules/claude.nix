{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    claude-code
  ];
}
