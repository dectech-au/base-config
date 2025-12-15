{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ 
    rar
    unrar
  ];
}
