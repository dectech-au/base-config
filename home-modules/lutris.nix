#./home-modules/lutris.nix
{ config, lib, pkgs, ... }:
{

  home-manager.users.leo = {
    programs.lutris.enable = true;
  };
}
