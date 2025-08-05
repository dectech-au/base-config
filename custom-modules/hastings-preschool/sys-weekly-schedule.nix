#/etc/nixos/custom-modules/hastings-preschool/weekly-schedule.nix
{ pkgs, ... }:

let
weeklyScheduleEnv = pkgs.python311.withPackages (ps: [
  ps.pdfplumber.overridePythonAttrs (_: { doCheck = false; })
  ps.openpyxl.overridePythonAttrs    (_: { doCheck = false; })
]);

in
{
  environment.systemPackages = [ weeklyScheduleEnv ];
}
