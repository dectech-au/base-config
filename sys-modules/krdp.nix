#/etc/nixos/sys-modules/krdp.nix
{ config, lib, pkgs, ... }:
{
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-kde ];
  };

  environment.systemPackages = with pkgs; [
    kdePackages.krdp    # cli server
    krdc                # kde rdp client
  ];

  networking.firewall.allowedTCPPorts = [ 3389 ];
}
