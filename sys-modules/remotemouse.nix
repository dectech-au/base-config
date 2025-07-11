# ~/.dotfiles/modules/remotemouse.nix

# bash 
# cd ~ && sudo rm -r .wine ##### clean wine prefix and start again

# wineserver -k                             ##### restart wine

##### Install these libraries 
# winetricks corefonts dinput directplay input8 nocrashdialog vcrun6 

##### Libraries which breaks shit:
# dotnet40 gdiplus

##### Force Wine to handle keyboard and mouse input:
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "UseTakeFocus" /d "Y" /f
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "UseXVidMode" /d "N" /f
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "GrabKeyboard" /d "Y" /f
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "GrabPointer" /d "Y" /f
# wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v "MouseWarpOverride" /d "force" /f

##### Input device permissions:
# sudo groupadd uinput && sudo usermod -aG input,uinput $(whoami) 

##### Run remote mouse
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
}
