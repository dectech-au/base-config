#/etc/nixos/custom-modules/hastings-preschool/weekly-schedule.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python311Packages.pdfplumber
    python311Packages.openpyxl
  ];
};
