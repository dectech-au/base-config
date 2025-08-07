#/etc/nixos/custom-modules/hastings-preschool/pdf2ods.nix
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
      ods="$dir/output.ods"

      # Extract table grid; keep exact column layout
      tabula-java --lattice --spreadsheet -p all -o "$csv" "$pdf"

      # Tell LibreOffice the CSV uses comma (44) & quote (34); no previews
      soffice --headless \
              --convert-to ods:"Text - txt - csv (StarCalc):44,34,76" \
              --outdir "$dir" "$csv" >/dev/null 2>&1

      mv -f "$dir/$base.ods" "$ods"
      rm -f "$csv"

      echo "✓ Wrote $ods"
    '';
  };

  home.packages = with pkgs; [
    tabula-java
    jdk17_headless
  ];
}
