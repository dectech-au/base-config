#/etc/nixos/sys-modules/star-rail-macro.nix
{ config, lib, pkgs, ... }:
{
environment.systemPackages = with pkgs; [
  grim
  slurp
  ydotool
  wl-clipboard
  imagemagick
  python3
  (python3.withPackages (ps: with ps; [ opencv-python numpy ]))
];

services.udev.extraRules = ''
  KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
'';

users.groups.input.members = [ "yourusername" ];

boot.kernelModules = [ "uinput" ];
}
