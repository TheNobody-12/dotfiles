{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    rbw
    age
    pinentry_mac
    gnupg
    wireguard-tools
  ];
}
