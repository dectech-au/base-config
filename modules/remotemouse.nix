# ~/.dotfiles/modules/remotemouse.nix or similar
{ config, lib, pkgs, ... }:
let
  remotemouse = pkgs.buildFHSUserEnv {
    name = "remotemouse";
    targetPkgs = pkgs: with pkgs; [
      xclip
      libxcb
      libx11
      libxinerama
      # add other missing libs as needed
    ];
    runScript = "./modules/RemoteMouse_x86_64/RemoteMouse"; # actual binary
  };
in {
  home.packages = [ remotemouse ];
}
