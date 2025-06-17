# ~/.dotfiles/modules/remotemouse.nix or similar
{ config, lib, pkgs, ... }:
  
pkgs.buildFHSEnv {
  name = "remotemouse";

  runScript = "${toString ../../Downloads/RemoteMouse_x86_64/RemoteMouse}";

  nativeBuildInputs = with pkgs; [
    clip
    glib
    gtk3
    dbus
    libxkbcommon
    libGL
    zlib
    freetype
    fontconfig
    stdenv.cc.cc

    # Qt and X11 dependencies
    qt5.qtbase
    qt5.qttools
    qt5.qtwayland
    xorg.xcbutil
    xorg.xcbutilwm
    xorg.libxcb
    xorg.libX11
    xorg.libXinerama
    xorg.libXext
    xorg.libXtst
    xorg.libXrender
    xorg.libXrandr
    xorg.libXfixes
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
  ];

  extraPkgs = with pkgs; [];

  shellHook = ''
    export DISPLAY=$DISPLAY
  '';
}
