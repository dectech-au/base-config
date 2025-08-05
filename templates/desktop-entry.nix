#/etc/nixos/templates/desktop-entry.nix
{ config, lib, pkgs, ... }:

{
  # enable management of XDG dirs and desktop entries
  xdg.enable = true;

  # define one or more .desktop files
  xdg.desktopEntries.myApp = {
    name        = "My App";
    genericName = "Awesome Tool";         # optional
    comment     = "Launch My App";
    exec        = "${pkgs.myApp}/bin/my-app %u";  # include %u if you want file/URL args
    icon        = "my-app";               # an icon name in your theme or full path
    categories  = [ "Utility" ];          # menu categories
    terminal    = false;                  # true if it needs a terminal
    mimeType    = [ "application/x-myapp" ]; # optional
    startupNotify = true;                 # optional
  };

  # you can add more entries under different keys
  xdg.desktopEntries.anotherTool = {
    name    = "Another Tool";
    exec    = "${pkgs.anotherTool}/bin/another-tool";
    icon    = "another-tool";
    categories = [ "Development" ];
    terminal = true;
  };
}
