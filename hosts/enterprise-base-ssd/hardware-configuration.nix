#/etc/nixos/hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ 
    "xhci_pci"       # USB-3 host
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "uas"
    "sd_mod"
    "sr_mod"
    "virtio_blk"
    "virtio_scsi"
    "virtio_pci"
  ];

  boot.initrd.kernelModules = [ ];
  
  boot.kernelModules = [ ]; # leave blank and let it autoload when present
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-partlabel/dectech-enterprise-ssd";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-partlabel/boot-ssd";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-partlabel/swap-ssd"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode   = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
