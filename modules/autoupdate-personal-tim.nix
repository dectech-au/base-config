#~/.dotfiles/modules/autoupdate-personal-tim.nix
{ config, lib, pkgs, ... }:
let
  scriptPath = "${config.users.users.dectec.home}/.dotfiles/update-personal-tim.sh";
in
{
  systemd.user.services.nix-flake-update = {
    description = "Auto update flake + switch";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = scriptPath;
    };
    wantedBy = [ "default.target" ];
  };

  systemd.user.timers.nix-flake-update-personal-tim = {
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
