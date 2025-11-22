{ config, lib, pkgs, ... };
{
  home.packages = [
    (pkgs.writeShellScriptBin "signal-desktop-nogpu" ''
      exec ${pkgs.signal-desktop}/bin/signal-desktop --disable-gpu "$@"
    '')
  ];
}
