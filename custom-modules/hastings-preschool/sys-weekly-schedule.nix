#/etc/nixos/custom-modules/hastings-preschool/weekly-schedule.nix
{ pkgs, ... }:

let
  weeklyScheduleEnv = pkgs.python311.withPackages (ps: [
    ps.pdfplumber
    ps.openpyxl
  ]);
in
{
  environment.systemPackages = [ weeklyScheduleEnv ];
}
