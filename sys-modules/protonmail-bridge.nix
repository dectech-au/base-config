#~/.dotfiles/modules/protonmail-bridge.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # protonmail-bridge
    protonmail-bridge-gui
  ];
  # services.protonmail-bridge.enable = true;
}
