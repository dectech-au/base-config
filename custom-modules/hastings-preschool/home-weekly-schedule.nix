{ config, pkgs, ... }:
let
  scriptRel = ".local/bin/weekly-booking.py";
  menuRel   = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
in
{
  ## 1) Copy the Python script into $HOME
  home.file."${scriptRel}" = {
    text       = builtins.readFile ./weekly-booking.py;  # <- this file must exist
    executable = true;
  };

  ## 2) Create the KF6 context-menu entry
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
    Exec=python3 "%h/${scriptRel}" "%f"
  '';

home.packages = with pkgs; [
  python311                                # <—— the interpreter
  (python311Packages.pdfplumber.overridePythonAttrs (_: { doCheck = false; }))
  (python311Packages.openpyxl  .overridePythonAttrs (_: { doCheck = false; }))
];

}
