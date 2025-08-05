#/etc/nixos/templates/inejct-text-to-file.nix
{ config, lib, pkgs, ... }:
{
    home.file."<location/and/filename.sh>".text = ''
      <contents-of-file>
  '';
}
