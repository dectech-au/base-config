#~/.dotfiles/sys-modules/sshfs.nix
{ config, lib, pkgs, ... }:
{

  system.fsPackages = [ pkgs.sshfs ];

# how to use:
# sshfs remote_user@machine:/remote/directory ~/local/directory
#
# or declaratively:

fileSystems."/home/Games/SteamLibrary-dectech-6af36c" = {
  device = "zozano@100.64.0.5:/home/SteamLibrary";
  fsType = "sshfs";
    options = [
    "nodev"
    "nofail"
    "_netdev"
    "reconnect"
    "ServerAliveInterval=15"
    "IdentityFile=/root/.ssh/id_ed25519"
    "uid=1000"
    "gid=100"
    "allow_other"
    "x-systemd.automount"
    "x-systemd.after=tailscaled.service"
    ];
  };
}
