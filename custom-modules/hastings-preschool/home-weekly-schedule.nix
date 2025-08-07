{ config, pkgs, ... }:

let
  scriptRel = ".local/bin/pdf2ods";
  menuRel   = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
in
{
home.file.".local/bin/pdf2ods" = {
  executable = true;
  text = ''
    #!/usr/bin/env bash
    set -euo pipefail

    pdf="$1"
    [[ -f "$pdf" ]] || { echo "No such file: $pdf" >&2; exit 1; }

    dir="$(dirname "$pdf")"
    base="$(basename "${pdf%.*}")"
    csv="$dir/$base.csv"
    ods="$dir/$base.ods"

    # lattice = use cell borders; -p all = every page
    tabula -lattice -p all -o "$csv" "$pdf"

    # --outdir ensures the ODS lands next to the PDF, not in $PWD
    soffice --headless --convert-to ods --outdir "$dir" "$csv" >/dev/null
    rm -f "$csv"

    echo "✓ Wrote $ods"
  '';
};


  home.file.".local/share/kio/servicemenus/convert-weekly-bookings.desktop".text = ''
    [Desktop Entry]
    Type=Service
    X-KDE-ServiceTypes=KFileItemAction/Plugin
    MimeType=application/pdf;
    X-KDE-Priority=TopLevel

    Actions=ConvertWeekly

    [Desktop Action ConvertWeekly]
    Name=Convert to ODS
    Icon=application-vnd.oasis.opendocument.spreadsheet
    Exec=${config.home.homeDirectory}/.local/bin/pdf2ods %f
  '';
}
