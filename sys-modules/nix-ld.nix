#~/.dotfiles/sys-modules/nix-ld.nix
{ config, lib, pkgs, ... }:

let
  legacyPkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/21.05.tar.gz";
    sha256 = "1ckzhh24mgz6jd1xhfgx0i9mijk6xjqxwsshnvq789xsavrmsc36";
  }) {
    system = "x86_64-linux";
  };
in

{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      glibc
      xorg.libX11
      xorg.libXext
      xorg.libXrandr
      xorg.libXtst
      alsa-lib
      libpulseaudio
      libxkbcommon
      libGL
      qt5.qtbase
      qt5.qttools
      qt5.qtsvg

      legacyPkgs.python37
    ];
  };
}
