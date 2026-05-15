{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    mpv
    transmission_4
  ];
}
