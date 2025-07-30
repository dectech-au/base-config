#~/.dotfiles/modules/birdtray.nix
{ config, lib, pkgs, ... }:
let
  myBirdtray = pkgs.birdtray.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [
      "-DOPT_THUNDERBIRD_CMDLINE=${pkgs.thunderbird}/bin/thunderbird"
    ];
  });
in
{
  environment.systemPackages = with pkgs; [
    myBirdtray
  ];
}
