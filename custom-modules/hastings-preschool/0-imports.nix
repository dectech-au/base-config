#/etc/nixos/custom-modules/hastings-preschool/0-imports
{ config, lib, pkgs, ... }:
{
  imports = [
    ./right-click-menu.nix
    #./text2ods.nix
    #./okular2csv.nix
    ./okular_txt_to_ods.nix
  ];

  home.packages = with pkgs; [
    python311
    python311Packages.pdfplumber
    python311Packages.odfpy
  ];
}
