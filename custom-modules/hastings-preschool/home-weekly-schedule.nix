#/etc/nixos/custom-modules/hastings-preschool/home-weekly-schedule.nix
{ config, lib, pkgs, ... }:
let
  bookingScript = ".scripts/weekly-booking.py";
  serviceMenu = ".local/share/kservices5/ServiceMenus/convert-weekly-bookings.desktop";
in
{
 home.file."${serviceMenu}".text = ''
    [Desktop Entry]
    Type=Service
    ServiceTypes=KonqPopupMenu/Plugin
    MimeType=application/pdf
    X-KDE-Priority=TopLevel

    Actions=ConvertWeekly

    [Desktop Action ConvertWeekly]
    Name=Convert to Spreadsheet
    Icon=application-vnd.ms-excel
    Exec=${config.home.homeDirectory}/${bookingScript} %u
  '';

  home.file."${bookingScript}" = {
    text = builtins.readFile ./weekly-booking.py;
    executable = true;
  };
}
