#~/.dotfiles/modules/bluetooth.nix
{ config, lib, pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # services.blueman.enable = true;
}
