{ config, lib, pkgs, ... }
{
  environment.systemPackages = with pkgs [
    cargo
    rustc
    pkg-config
    libpcap
    wayland
    wayland-protocols
    libxkbcommon
    openssl
    clang
    llvmPackages.bintools
    libcap
    python3
  ];
}
