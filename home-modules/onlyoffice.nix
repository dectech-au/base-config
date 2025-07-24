#/etc/nixos/home-modules/onlyoffice.nix
{ config, lib, pkgs, ... }:
let
  onlyofficeEnv = pkgs.buildFHSUserEnv {
    name       = "onlyoffice";
    targetPkgs = pkgs: with pkgs; [
      onlyoffice-bin
      cantarell-fonts
    ];
    multiPkgs = true;
    runScript  = "desktopeditors";
  };
in
{
  home.packages = [ onlyofficeEnv ];
}
