# ~/.dotfiles/modules/remotemouse.nix or similar

##### Clean wine prefix and start again:
# WINEPREFIX=~/wine-remote-clean winecfg

##### Restart wine:
# wineserver -k

##### Test GrabPointer:
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "GrabPointer" /d "Y" /f


##### setup:

##### Enable MouseWarpOverrive (maybe?)
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "MouseWarpOverride" /d "force" /f

##### Install .NET components (maybe?)
# winetricks dotnet40

##### Also try:
# winetricks corefonts gdiplus vcrun6

##### also try:
# winetricks nocrashdialog
# winetricks sandbox

##### Force Wine to handle keyboard and mouse input:
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "UseTakeFocus" /d "Y" /f
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "UseXVidMode" /d "N" /f
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "GrabKeyboard" /d "Y" /f
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "GrabPointer" /d "Y" /f
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "MouseWarpOverride" /d "force" /f

##### Use winetricks to install input support libraries:
# winetricks dinput dinput8 directplay

##### Input device permission test:
# sudo groupadd uinput
# sudo usermod -aG input,uinput $(whoami)

##### run remote mouse with
# cd ~/.wine/drive_c/Program\ Files\ \(x86\)/Remote\ Mouse/ && WINEDEBUG=+cursor,+event,+x11drv wine RemoteMouse.exe


{ config, lib, pkgs, ... }:
{

  networking.firewall = {
    allowedTCPPorts = [ 1978 ];
    allowedUDPPorts = [ 1978 ];
  };

  environment.systemPackages = with pkgs; [
    winetricks
    wineWowPackages.staging
  ];
  # environment.systemPackages = with pkgs; [
  #   clip
  #   glib
  #   gtk3
  #   dbus
  #   libxkbcommon
  #   libGL
  #   zlib
  #   freetype
  #   fontconfig
  #   stdenv.cc.cc
  #   patchelf
  #
  #   # Qt and X11 dependencies
  #   qt5.qtbase
  #   qt5.qttools
  #   qt5.qtwayland
  #   xorg.xcbutil
  #   xorg.xcbutilwm
  #   xorg.libxcb
  #   xorg.libX11
  #   xorg.libXinerama
  #   xorg.libXext
  #   xorg.libXtst
  #   xorg.libXrender
  #   xorg.libXrandr
  #   xorg.libXfixes
  #   xorg.xcbutilimage
  #   xorg.xcbutilkeysyms
  #   xorg.xcbutilrenderutil
  # ];
}
