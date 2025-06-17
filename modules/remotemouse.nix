# ~/.dotfiles/modules/remotemouse.nix or similar
{ config, lib, pkgs, ... }:
let
  remotemouse = pkgs.buildFHSEnv {
    name = "remotemouse";
    targetPkgs = pkgs: with pkgs; [
      dbus
      freetype
      fontconfig
      glib
      gtk3
      libGL
      python37
      python37Packages.pyqt5
      qt5.qtbase
      qt5.qtwayland
      qt5.qttools
      stdenv.cc.cc
      xclip
      xorg.libxcb
      xorg.libX11
      xorg.libXinerama
      xorg.libXext
      xorg.libXtst
      xorg.libXrender
      xorg.libXrandr
      xorg.libXfixes
      zlib
      # add other missing libs as needed
    ];
    runScript = "./modules/RemoteMouse_x86_64/RemoteMouse"; # actual binary
  };
in {
  home.packages = [ remotemouse ];
}
