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
      
      tabula-java --lattice --spreadsheet -p all -o "$csv" "$pdf"
      
      # --------------- New, simpler conversion ---------------
      ssconvert "$csv" "$ods" >/dev/null 2>&1
      # -------------------------------------------------------
      
      rm -f "$csv"
      echo "✓ Wrote $ods"
    '';
  };

  home.packages = with pkgs; [
    tabula-java
    jdk17_headless
  ];
}
