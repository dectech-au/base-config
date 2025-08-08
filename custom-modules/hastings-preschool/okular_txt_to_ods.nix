# /etc/nixos/custom-modules/hastings-preschool/okular_txt_to_ods.nix
{ config, pkgs, ... }:

let
  pythonWithOdf = pkgs.python311.withPackages (ps: [ ps.odfpy ]);
in
{
  # 1) Install the interpreter that *includes* odfpy
  home.packages = [ pythonWithOdf ];

  # 2) Drop your Python script body from disk (no Unicode ellipsis!)  
  #    Keep the shebang as /usr/bin/env python3 inside the file; we’ll wrap it.
  home.file.".local/bin/okular_txt_to_ods.py" = {
    executable = true;
    text = builtins.readFile ./okular_txt_to_ods.py;  # <-- the script body I gave you earlier
  };

  # 3) Add a tiny launcher that forces the right interpreter
  home.file.".local/bin/okular_txt_to_ods" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec ${pythonWithOdf}/bin/python "$HOME/.local/bin/okular_txt_to_ods.py" "$@"
    '';
  };
}
