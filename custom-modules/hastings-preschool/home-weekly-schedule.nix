#/etc/nixos/custom-modules/hastings-preschool/home-weekly-schedule.nix
{ config, lib, pkgs, ... }:
let
  bookingScript = ".scripts/weekly-booking.py";
in
{
  # enable management of XDG dirs and desktop entries
  xdg.enable = true;

  # define one or more .desktop files
  xdg.desktopEntries.convert_weekly_bookings = {
    name        = "Convert Weekly Bookings";
    genericName = "convert-weekly-bookings";         # optional
    comment     = "Turn Hastings Preschool’s PDF roster into a spreadsheet";
    exec        = "${pkgs.bash}/bin/bash -c '${config.home.homeDirectory}/${bookingScript} %f'";
    icon        = "accessories-text-editor";               # an icon name in your theme or full path
    categories  = [ "Office" "Utility" ];          # menu categories
    terminal    = false;                  # true if it needs a terminal
    mineType    = [ "application/pdf" ];
    #startupNotify = true;                 # optional
  };

  home.file."${bookingScript}" = {
    text = builtins.readFile ./weekly-booking.py;
    executable = true;
  };
}
