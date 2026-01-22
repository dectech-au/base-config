{ config, lib, pkgs, ... }:
{
  fileSystems = {
    "/server" = {
      device = "z-home@z-home-mac:/";
      fsType = "sshfs";
      options = [
        "nodev"
        "nofail"
        "allow_other"
        "IdentityFile=/root/.ssh/home-server_z-nix"
        "x-systemd.automount"
        "x-systemd.requires=network-online.target"
      ];
    };
  };
}
