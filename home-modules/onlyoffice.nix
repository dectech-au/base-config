#/etc/nixos/home-modules/onlyoffice.nix
{ config, lib, pkgs, ... }:
let
  onlyofficeEnv = pkgs.runFHSUserEnv {
    name       = "onlyoffice";
    targetPkgs = ps: with ps; [ onlyoffice-bin cantarell-fonts ];
    runScript  = "desktopeditors";
  };
in
{
  programs.onlyoffice = {
    enable = false;;
    package = pkgs.onlyoffice-bin;
    settings = {};
  };
  
  home.packages = [ onlyofficeEnv ];
}
