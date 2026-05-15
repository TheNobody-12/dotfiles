{ config, pkgs, ... }:

{
  # Neovim is installed via home.packages to avoid home-manager
  # overwriting ~/.config/nvim/init.lua. The full Neovim config
  # lives in ~/dotfiles/.config/nvim and is symlinked to ~/.config/nvim.
  home.packages = with pkgs; [ neovim ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
