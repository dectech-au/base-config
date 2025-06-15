#/etc/nixos/modules/onlyoffice.nix
{ config, lib, pkgs, ... }:

{
	# services.onlyoffice.enable = true;
	environment.systemPackages = with pkgs; [
		onlyoffice-bin
	];

  xdg.desktopEntries.only-office = {
    name = "OnlyOffice";
    exec = "onlyoffice-desktopeditors";
    icon = "ms-office";
    terminal = false;
    type = "Application";
    categories = [ "Office" ];
  };
}
