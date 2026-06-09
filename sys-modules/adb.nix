{ config, lib, pkgs, ... }:
{
  programs.adb.enable = true;
  users.users.dectec.extraGroups = [ "adbusers" ];
}
