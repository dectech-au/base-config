{ config, pkgs, ... }:
{
  home.file.".local/bin/pdf2ods" = {
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
}
