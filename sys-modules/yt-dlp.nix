{ config, lib, pkgs, ... }:
{
  home-manager.users.dectec = {
    programs.yt-dlp = {
      enable = true;
      settings = {
        merge-output-format = "mkv";
        format = "bestvideo+bestaudio/best";
        embed-metadata = true;
        embed-thumbnail = true;
        embed-subs = true;
        sub-langs = "en";
        sponsorblock-mark = "all";
      };
    };
  };
}
