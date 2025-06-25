#~/.dotfiles/modules/autoupdate.nix
{ config, lib, pkgs, ... }:
let
  scriptPath = "${config.users.users.dectec.home}/.dotfiles/update-enterprise-base.sh";
in
{
  systemd.user.services.nix-flake-update-enterprise-base = {
    description = "Auto update flake + switch";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = scriptPath;
    };
    wantedBy = [ "default.target" ];
  };

  systemd.user.timers.nix-flake-update-enterprise-base = {
    description = "Daily flake auto-update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Optional: ensure script is executable (if not already)
  system.activationScripts.makeScriptExecutable = ''
    chmod +x ${scriptPath}
  '';
}
