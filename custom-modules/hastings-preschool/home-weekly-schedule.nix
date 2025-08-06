{ config, pkgs, ... }:

let
  pythonWithPkgs = pkgs.python311.withPackages (ps: [
    ps.pdfplumber
    ps.openpyxl
  ]);

  scriptRel   = ".local/bin/weekly-booking.py";
  menuRel     = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
in
{
  home.file."${scriptRel}" = {
    text       = builtins.readFile ./weekly-booking.py;
    executable = true;
  };

  home.file."${menuRel}".text = ''
    [Desktop Entry]
    Type=Service
    X-KDE-ServiceTypes=KFileItemAction/Plugin
    MimeType=application/pdf;
    X-KDE-Priority=TopLevel

    Actions=ConvertWeekly

    [Desktop Action ConvertWeekly]
    Name=Convert to Spreadsheet
    Icon=application-vnd.ms-excel
    Exec=${pythonWithPkgs}/bin/python "%h/${scriptRel}" "%f"
  '';
}
