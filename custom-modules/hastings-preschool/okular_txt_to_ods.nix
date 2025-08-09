# /etc/nixos/custom-modules/hastings-preschool/okular_txt_to_ods.nix
{ config, pkgs, ... }:

let
  pyEnv = pkgs.python311.withPackages (ps: [
    ps.odfpy
    (ps.pdfplumber.overridePythonAttrs (_: { doCheck = false; }))
    # pdfplumber pulls pdfminer.six + Pillow itself; leave them out.
  ]);
in
{
  # Single python env with both deps (DO NOT also install pkgs.python311 elsewhere)
  home.packages = [ pyEnv ];

  # The script you want to run (make sure this is the *PDF* version if that’s your plan)
  home.file.".local/bin/pdf_to_ods_boxes.py" = {
    executable = true;
    text = builtins.readFile ./pdf_to_ods_boxes.py;
  };

  # Thin launcher that forces the right interpreter
  home.file.".local/bin/pdf2ods" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec ${pyEnv}/bin/python "$HOME/.local/bin/pdf_to_ods_boxes.py" "$@"
    '';
  };
}
