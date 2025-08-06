{ config, pkgs, ... }:

let
  # Minimal interpreter that already carries pdfplumber + openpyxl
  pythonWithPkgs = pkgs.python311.withPackages (ps: [
    ps.pdfplumber
    (ps.openpyxl.overridePythonAttrs (_: { doCheck = false; }))  # no torch build
  ]);

  scriptRel = ".local/bin/weekly-booking.py";   # name matches the simple script
  menuRel   = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
in
{
  ## 1. Drop the script into $HOME (it’s the dumb one-to-one converter)
  home.file."${scriptRel}" = {
    text       = builtins.readFile ./weekly-booking.py;
    executable = true;
  };

  ## 2. Service-menu entry (KF6, works on right-click)
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
