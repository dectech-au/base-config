#~/.dotfiles/sys-modules/esphome.nix
{ config, lib, pkgs, ... }:
{
  services.esphome = {
    enable = true;
    openFirewall = true;
    allowedDevices = [
      "char-ttyUSB"
      "/dev/serial/by-id/usb-Revolabs_flx_base_AK066AVS-if00-port0"
    ];
  };
}
