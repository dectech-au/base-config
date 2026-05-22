{
  config,
  lib,
  pkgs,
  ...
}: {
  services.printing = {
    enable = true;
    drivers = [pkgs.brlaser];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    system-config-printer
  ];
}
