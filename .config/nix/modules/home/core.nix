{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    lazygit
    zellij
    btop
    fastfetch
    yazi
    cmus
    mpd
    rmpc
    zsh-fzf-tab

    # Performance / QoL
    atuin
    bat
    eza
    delta
    hyperfine
    macmon
    rm-improved
    ripgrep-all

    # Optional AI assistants (remove any you don't use)
    gemini-cli
    ollama
    opencode
    claude-code
    qwen-code
  ];

  programs.home-manager.enable = true;

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;
      update_check = false;
      enter_accept = false;
    };
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      # Source the manual .zshrc
      if [ -f $HOME/.config/zsh/.zshrc ]; then
        source $HOME/.config/zsh/.zshrc
      fi

      # Ensure ZDOTDIR is set for future shells
      export ZDOTDIR=$HOME/.config/zsh

      # fzf-tab (must load after compinit)
      if [ -f "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh" ]; then
        source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
      elif [ -f "${pkgs.zsh-fzf-tab}/share/zsh-fzf-tab/fzf-tab.plugin.zsh" ]; then
        source "${pkgs.zsh-fzf-tab}/share/zsh-fzf-tab/fzf-tab.plugin.zsh"
      fi
    '';

    shellAliases = {
      cat = "bat";
      v = "nvim";
      vi = "nvim";
      vim = "nvim";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$python$character";
      right_format = "$cmd_duration";
      character.success_symbol = "[➜](bold green)";
      character.error_symbol = "[➜](bold red)";
      directory.truncate_to_repo = true;
      git_branch.format = "[$branch]($style) ";
      git_status.format = "[$all_status$ahead_behind]($style) ";
      python.format = "[\${symbol}\${virtualenv}]($style) ";
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = false;
      line-numbers = true;
    };
  };

  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      user = {
        name = "gravity";
        email = "gravity@example.com";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      commit.gpgsign = true;
      core.sshCommand = "ssh -o IdentitiesOnly=yes";
    };
  };

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  home.sessionVariables = {
    _ZO_DOCTOR = "0";
    HOMEBREW_NO_AUTO_UPDATE = "1";
  };
}
