# ~/.dotfiles/modules/remotemouse.nix or similar
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
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
    patchelf

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
}
