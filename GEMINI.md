# 🌌 Gravity's macOS Rice: Gemini Context

This repository is a declarative macOS "rice" (dotfiles) built for Apple Silicon (aarch64-darwin). It uses **nix-darwin** for system-level management and **Home Manager** for user-space configurations.

## 🏗 Project Overview

*   **OS**: macOS (Sonoma/Sequoia+)
*   **System Manager**: `nix-darwin` (configured in `.config/nix/flake.nix`)
*   **User Config**: `home-manager` (configured in `.config/nix/home.nix`)
*   **Window Manager**: `yabai` (Tiling WM)
*   **Hotkeys**: `skhd` (Key daemon)
*   **Status Bar**: `sketchybar` (Dynamic bar)
*   **Terminal**: `ghostty` (GPU-accelerated)
*   **Editor**: `neovim` (Custom NvChad-inspired structure)
*   **Shell**: `zsh` (with `zoxide`, `fzf`, and custom completion)
*   **File Manager**: `yazi` (TUI)
*   **Music**: `mpd` + `rmpc` (TUI client)

## 🛠 Operational Commands

### Nix Management
*   **Rebuild System**: `sudo darwin-rebuild switch --flake .#air` (Execute from `~/.config/nix`)
*   **Update Inputs**: `nix flake update`
*   **Garbage Collection**: `nix-store --gc`

### Theme Switching
*   **Set Theme**: `bash ~/.config/themes/set_theme.sh <ThemeName>`
    *   Supported: `Catppuccin`, `Gruvbox`

### Neovim Integration
*   **Compile Document**: `<leader>l` (Uses `~/.local/bin/compiler`)
*   **Open Output**: `<leader>p` (Uses `~/.local/bin/opout`)

## ⌨️ Key Hotkeys (skhd)

| Action | Keybinding |
| :--- | :--- |
| **Focus Window** | `lalt - {h, j, k, l}` |
| **Focus Space** | `lalt - {1-7}` |
| **Move Window** | `shift + lalt - {h, j, k, l}` |
| **Full Screen** | `shift + lalt - f` |
| **Close Window** | `lalt - q` |
| **Float Window** | `lalt - d` |
| **Open Ghostty**| `lalt - t` |
| **Toggle Bar**  | `shift + lalt - space` |

## 🐚 Shell Environment (Zsh)

*   **Aliases**: `v` -> `nvim`, `ls` -> `ls -G`, `cd` -> `zoxide`
*   **Custom Functions**:
    *   `y`: Launches `yazi` and changes the shell's CWD to yazi's last directory on exit.
    *   `venv <name>`: Activates a Python virtual environment from `~/Python_Env`.
*   **Navigation**: `Ctrl-f` to fuzzy find and `cd` into a directory.

## 📂 Key Directories & Files

*   `.config/nix/`: Core Nix configuration (Flake & Home Manager).
*   `.config/nvim/`: Neovim setup (Lazy.nvim, core, plugins).
*   `.config/sketchybar/`: Status bar configuration and plugins.
*   `.config/yabai/`: Tiling window manager rules.
*   `.config/skhd/`: Global hotkey mappings.
*   `.local/bin/`: Collection of custom utility scripts (e.g., `compiler`, `opout`, `sysact`, `setbg`).

## 🛠 Development Conventions

1.  **Declarative Config**: Prefer managing packages and services via `flake.nix` or `home.nix` whenever possible.
2.  **Scripts over Manual Action**: Use and maintain scripts in `.local/bin` for repetitive tasks.
3.  **Path Resolution**: Use `$HOME` or absolute paths in scripts to ensure compatibility with `sudo` execution (like `darwin-rebuild`).
4.  **Theme Agnostic**: New configurations should ideally respect the theme symlink structure in `.config/themes/current`.
