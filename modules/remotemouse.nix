# ~/.dotfiles/modules/remotemouse.nix or similar
{ config, lib, pkgs, ... }:
let
  remotemouse = pkgs.buildFHSEnv {
    name = "remotemouse";
    targetPkgs = pkgs: with pkgs; [
      glib
      libGL
      xclip
      xorg.libxcb
      xorg.libX11
      xorg.libXinerama
      zlib
      # add other missing libs as needed
    ];
    runScript = "./modules/RemoteMouse_x86_64/RemoteMouse"; # actual binary
  };
in {
  home.packages = [ remotemouse ];
}
