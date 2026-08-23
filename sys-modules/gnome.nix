#/etc/nixos/sys-modules/gnome.nix
{ ... }:

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Mutter defaults to card0 (NVIDIA dGPU), which has no display outputs
  # under PRIME offload. Pin the primary GPU to the i915 iGPU at
  # PCI 0000:00:02.0 — matches hardware.nvidia.prime.intelBusId.
  # Matched by PCI slot, not card number: enumeration order is unstable.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", ENV{DEVNAME}=="/dev/dri/card[0-9]", KERNELS=="0000:00:02.0", TAG+="mutter-device-preferred-primary"
  '';

  services.displayManager.autoLogin = {
    enable = true;
    user = "leo";
  };
}
