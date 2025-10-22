{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python312Packages.openai-whisper
  ];
}
