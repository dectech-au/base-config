{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
  trezor-suite
  trezorctl
  ];

  services.trezord.enable = true;
  #services.udev.packages = with pkgs; [ trezor-udev-rules ];
}
