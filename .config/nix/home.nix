{ config, pkgs, ... }:

{
  home.stateVersion = "23.11";

  imports = [
    ./modules/home/core.nix
    ./modules/home/dev.nix
    ./modules/home/media.nix
    ./modules/home/nvim.nix
    ./modules/home/security.nix
  ];
}
