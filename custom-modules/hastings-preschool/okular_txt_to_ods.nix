#/etc/nixos/custom-modules/hastings-preschool/okular_txt_to_ods.nix
{ config, pkgs, ... }:
let
  pythonWithOdf = pkgs.python311.withPackages (ps: [ ps.odfpy ]);
in

{
  home.packages = [ pythonWithOdf ];

  home.file.".local/bin/okular_txt_to_ods.py" = {
    executable = true;
    text = builtins.readFile ./okular_txt_to_ods.py;
  };
}
