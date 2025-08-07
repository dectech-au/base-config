#/etc/nixos/custom-modules/hastings-preschool/right-click-menu.nix
{ config, lib, pkgs, ... }:
{
  home.file."${menuRel}".text = ''
    [Desktop Entry]
    Type=Service
    X-KDE-ServiceTypes=KFileItemAction/Plugin
    MimeType=application/pdf;
    X-KDE-Priority=TopLevel

    Actions=ConvertWeekly

    [Desktop Action ConvertWeekly]
    Name=Convert to ODS
    Icon=application-vnd.oasis.opendocument.spreadsheet
    Exec=${config.home.homeDirectory}/${scriptRel} %f
  '';
}
