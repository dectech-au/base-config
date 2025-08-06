{ config, pkgs, ... }:

let
  # 1. Simple helper script – PDF ➜ CSV ➜ ODS
  scriptRel = ".local/bin/pdf2ods";   # will live in $HOME/.local/bin
  menuRel   = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
in
{
  ## 1. Install the helper script
  home.file."${scriptRel}" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      pdf="$1"
      [[ -f "$pdf" ]] || { echo "No such file: $pdf" >&2; exit 1; }

      base="${pdf%.*}"
      csv="${base}.csv"
      ods="${base}.ods"

      # lattice = use cell borders; -p all = every page
      tabula -lattice -p all -o "$csv" "$pdf"

      # convert CSV ➜ ODS
      soffice --headless --convert-to ods "$csv" >/dev/null

      rm -f "$csv"
      echo "✓ Wrote $ods"
    '';
  };

  ## 2. KDE service-menu entry (Plasma 6)
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

  ## 3. Packages needed at runtime
  home.packages = [
    pkgs.tabula-java   # table extractor
    pkgs.libreoffice   # soffice for CSV ➜ ODS
  ];
}
