{ config, lib, pkgs, ... }:
{
  services.input-remapper = {
    enable = true;
    enableUdevRules = true;
    serviceWantedBy = [ "multi-user.target" ];
  };

  environment.systemPackages = with pkgs; [
    input-remapper
  ];
}
