{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildImputs = [
    pkgs.wineWowPackages.full
    pkgs.winetricks
  ];
}
