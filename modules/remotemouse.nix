# ~/.dotfiles/modules/remotemouse.nix or similar
{ config, lib, pkgs, ... }:
let
  remotemouse-fhs = pkgs.buildFHSEnv {
    name = "remotemouse";
    targetPkgs = pkgs: with pkgs; [
      wayland-xcomposite-egl
      xclip
      glib
      gtk3
      dbus
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

    # Force xcb platform to avoid wayland issues
    runScript = ''
      env QT_QPA_PLATFORM=xcb /home/dectec/.dotfiles/modules/RemoteMouse_x86_64/RemoteMouse
    '';
  };
in {
  home.packages = [ remotemouse-fhs ];
}
