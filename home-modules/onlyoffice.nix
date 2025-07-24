#/etc/nixos/home-modules/onlyoffice.nix
{ config, lib, pkgs, ... }:
let
  onlyofficeEnv = pkgs.buildFHSEnv {
    name       = "onlyoffice";
    targetPkgs = pkgs: with pkgs; [
      onlyoffice-bin
      cantarell-fonts
    ];
    runScript  = "desktopeditors";
  };
in
{
  home.packages = [ onlyofficeEnv ];
}
