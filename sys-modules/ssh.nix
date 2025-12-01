#/etc/nixos/sys-modules/ssh-add.nix
{ config, lib, pkgs, ... }:
{
  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;
  services.openssh.enable = true;
  #PasswordAuthentication = false;
}
