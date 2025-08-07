{ config, pkgs, ... }:

let
  scriptRel = ".local/bin/pdf2ods";
  menuRel   = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
in
{
  ## 1.  Helper script: PDF ➜ CSV ➜ ODS
  home.file."${scriptRel}" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      pdf="$1"
      [[ -f "$pdf" ]] || { echo "No such file: $pdf" >&2; exit 1; }

      dir="$(dirname "$pdf")"
      base="$(basename "''${pdf%.*}")"
      csv="$dir/$base.csv"
      ods="$dir/$base.ods"

      # lattice = use cell borders; -p all = every page
      tabula-java -lattice -p all -o "$csv" "$pdf"

      # convert CSV → ODS in the same directory as the PDF
      soffice --headless --convert-to ods --outdir "$dir" "$csv" >/dev/null
      rm -f "$csv"

      echo "✓ Wrote $ods"
    '';
  };

  ## 2.  KDE Plasma-6 service-menu (right-click action)
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
    Exec=${config.home.homeDirectory}/${scriptRel} %f
  '';

  ## 3.  Runtime packages
  home.packages = [
    pkgs.tabula-java     # provides the `tabula` wrapper
    pkgs.libreoffice     # provides `soffice`
  ];
}
