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
      ods="$dir/output.ods"           # always the same target name

      # --spreadsheet keeps column structure; -lattice follows cell borders
      tabula-java --spreadsheet -lattice -p all -o "$csv" "$pdf"

      # LibreOffice converts CSV → ODS in the same dir
      soffice --headless --convert-to ods --outdir "$dir" "$csv" >/dev/null
      rm -f "$csv"

      echo "✓ Wrote $ods"
    '';
  };

  home.packages = with pkgs; [
    tubula-java
    jdk17_headless
  ];
}
