# ~/.dotfiles/modules/remotemouse.nix or similar
{ config, lib, pkgs, ... }:
let
  remotemouse = pkgs.buildFHSEnv {
    name = "remotemouse";
    targetPkgs = pkgs: with pkgs; [
      xclip
      xorg.libxcb
      xorg.libx11
      xorg.libXinerama
      # add other missing libs as needed
    ];
    runScript = "./modules/RemoteMouse_x86_64/RemoteMouse"; # actual binary
  };
in {
  home.packages = [ remotemouse ];
}
