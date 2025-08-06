# ~/.dotfiles/custom-modules/hastings-preschool/home-weekly-schedule.nix
{ config, pkgs, ... }:

let
  # files under $HOME
  scriptRel = ".local/bin/pdf2xlsx.py";   # use the simple script now in canvas
  menuRel   = ".local/share/kio/servicemenus/convert-weekly-bookings.desktop";
in
{
  ## 1. Minimal runtime environment (no custom interpreter)
  home.packages = with pkgs.python311Packages; [
    pdfplumber
    #openpyxl
  ];

  ## 2. Install the script
home.file."${scriptRel}".text = ''
  #!/usr/bin/env python3
  """
  pdf2xlsx – dumb one-to-one converter
  ====================================
  [...]   # paste entire script here
  """
  from __future__ import annotations
  import sys
  ...
'';


  ## 3. KDE 6 context-menu entry
  home.file."${menuRel}".text = ''
    [Desktop Entry]
    Type=Service
    X-KDE-ServiceTypes=KFileItemAction/Plugin
    MimeType=application/pdf;
    X-KDE-Priority=TopLevel

    Actions=ConvertWeekly

    [Desktop Action ConvertWeekly]
    Name=Convert to Spreadsheet
    Icon=application-vnd.ms-excel
    Exec=python3 "%h/${scriptRel}" "%f"
  '';
}
