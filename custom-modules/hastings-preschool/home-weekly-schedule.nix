#/etc/nixos/custom-modules/hastings-preschool/home-weekly-schedule.nix
{ config, pkgs, ... }:

let
  scriptRelPath      = ".local/bin/weekly-booking.py";
  serviceMenuRelPath = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
  scriptSource       = builtins.readFile ./weekly-booking.py;
in
{
  # 2.1  The converter script itself
  home.file."${scriptRelPath}" = {
    text       = scriptSource;
    executable = true;
  };

  # 2.2  Right-click “Convert to Spreadsheet” for any PDF
  home.file."${serviceMenuRelPath}".text = ''
[Desktop Entry]
Type=Service
X-KDE-ServiceTypes=KFileItemAction/Plugin
MimeType=application/pdf;
X-KDE-Priority=TopLevel

Actions=ConvertWeekly

[Desktop Action ConvertWeekly]
Name=Convert to Spreadsheet
Icon=application-vnd.ms-excel
Exec=/home/dectec/.local/bin/weekly-booking.py %f

  '';
}
