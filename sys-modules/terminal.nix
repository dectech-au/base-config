{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    yakuake
  ];

  programs = {
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        character = { success_symbol = ">"; error_symbol = ">"; };
      };
    };
  };
}
