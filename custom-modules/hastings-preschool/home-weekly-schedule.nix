{ config, pkgs, ... }:
{
  home.file.".local/bin/weekly-booking.py" = {
    text       = builtins.readFile ./weekly-booking.py;
    executable = true;
  };

  home.file.".local/share/kio/servicemenus/convert-weekly-bookings.desktop".text = ''
    [Desktop Entry]
    Type=Service
    X-KDE-ServiceTypes=KFileItemAction/Plugin
    MimeType=application/pdf;
    X-KDE-Priority=TopLevel

    Actions=ConvertWeekly

    [Desktop Action ConvertWeekly]
    Name=Convert to Spreadsheet
    Icon=application-vnd.ms-excel
    Exec=python3 "%h/.local/bin/weekly-booking.py" "%f"
  '';

  home.packages = with pkgs; [
    python311
    (python311Packages.pdfplumber.overridePythonAttrs (_: { doCheck = false; }))
    (python311Packages.openpyxl  .overridePythonAttrs (_: { doCheck = false; }))
  ];

}
