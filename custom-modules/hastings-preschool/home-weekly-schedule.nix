{ config, pkgs, ... }:

let
  scriptRel = ".local/bin/pdf2ods";   # helper lives here
  menuRel   = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
in
{
  ## 1. PDF ➜ CSV ➜ ODS helper
  home.file."${scriptRel}" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      pdf="$1"
      [[ -f "$pdf" ]] || { echo "No such file: $pdf" >&2; exit 1; }

      base="''${pdf%.*}"
      csv="''${base}.csv"
      ods="''${base}.ods"

      tabula -lattice -p all -o "$csv" "$pdf"
      soffice --headless --convert-to ods "$csv" >/dev/null
      rm -f "$csv"

      echo "✓ Wrote $ods"
    '';
  };

  ## 2. KDE Plasma-6 service-menu (right-click action)
  home.file."${menuRel}".text = ''
    [Desktop Entry]
    Type=Service
    X-KDE-ServiceTypes=KFileItemAction/Plugin
    MimeType=application/pdf;
    X-KDE-Priority=TopLevel

    Actions=ConvertWeekly

    [Desktop Action ConvertWeekly]
    Name=Convert to ODS
    Icon=application-vnd.oasis.opendocument.spreadsheet
    Exec="%h/${scriptRel}" "%f"
  '';

  ## 3. Runtime packages
  home.packages = [
    pkgs.tabula-java   # table extractor
    pkgs.libreoffice   # soffice for CSV ➜ ODS
  ];
}
