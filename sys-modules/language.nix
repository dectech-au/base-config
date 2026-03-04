{ config, lib, pkgs, ... }:
{
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      noto-fonts-cjk-sans  # covers Hangul well
      nanum                # common Korean font family (extra coverage)
      noto-fonts-color-emoji     # optional, helps with emoji in chats
    ];
  };
}
