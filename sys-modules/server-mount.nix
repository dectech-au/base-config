{ config, lib, pkgs, ... }:
{
  fileSystems = {
    "/server" = {
      device = "z-home@192.168.1.157:/";
      fsType = "sshfs";
      options = [
        "nodev"
        "nofail"
        "allow_other"
        "IdentityFile=/root/.ssh/id_ed25519_nixos"
        "x-systemd.automount"
        "x-systemd.requires=network-online.target"
      ];
    };
  };
}
