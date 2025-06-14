{ config, lib, pkgs, ... }:
{
  environment.systemPacakages = with pkgs; [
    btrfs-progs
    parted
  ];
}
