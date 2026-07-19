{ config, lib, pkgs, ... }: 
{
  systemd.services."NetworkManager-wait-online".enable = false;

  environment.systemPackages = with pkgs; [
    iproute2
  ];
}
