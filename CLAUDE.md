# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Nature

Declarative macOS "rice" (dotfiles) for Apple Silicon (`aarch64-darwin`). Not a software project — no build/test/lint pipeline. The "build" is a system rebuild via `nix-darwin`. `~/.config` and `~/.local` in `$HOME` are symlinks into this repo; edits here apply live (except for files owned by Nix, which require a rebuild).

## Apply / Rebuild Commands

All Nix work runs from `~/.config/nix` (which is `.config/nix/` in this repo). Host flake attribute is `air`, user is `gravity`.

```bash
# Apply config changes (flake.nix / home.nix / any module)
cd ~/.config/nix && sudo darwin-rebuild switch --flake .#air

# Bump flake inputs, then rebuild
cd ~/.config/nix && nix flake update && sudo darwin-rebuild switch --flake .#air

# Eval check (fast, no sudo needed)
cd ~/.config/nix && nix flake check

# GC + store optimization
nix-store --gc && nix-store --optimise
```

A weekly GC (`Sundays 03:00`, `--delete-older-than 14d`) is already declared in `modules/system.nix`.

## Architecture — Modular Nix Config

The flake was split from a single-file monolith into a module tree. This keeps concerns separated and makes rebuild evaluation faster.

```
.config/nix/
├── flake.nix              # inputs + host declaration only
├── home.nix               # home-manager entry point (imports sub-modules)
├── modules/
│   ├── system.nix         # nix settings, GC, users, activation scripts, DNS
│   ├── darwin.nix         # homebrew, yabai, skhd, sketchybar, syncthing
│   └── home/
│       ├── core.nix       # zsh, git, starship, direnv, atuin, bat, eza, delta
│       ├── dev.nix        # python, c, typst, latex, docs tooling
│       ├── media.nix      # mpd, ffmpeg, mpv, transmission
│       ├── nvim.nix       # neovim package (plain, NOT programs.neovim)
│       └── security.nix   # rbw, gpg, age, wireguard-tools
```

### Critical Design Choice: Neovim is NOT managed by `programs.neovim`

`programs.neovim.enable = true` in home-manager writes `~/.config/nvim/init.lua`. Since `~/.config/nvim` symlinks into `~/dotfiles/.config/nvim`, HM followed the symlink and overwrote the real `init.lua` with an empty generated file. **This is why neovim went "vanilla" after a rebuild.**

The fix: `modules/home/nvim.nix` installs neovim via `home.packages` only, with `programs.neovim` completely removed. The full Lazy.nvim + NvChad config lives in `.config/nvim/` and is never touched by Nix.

**Rule**: Never re-enable `programs.neovim.enable` or `programs.neovim.withPython3` etc. If neovim needs plugins or build inputs, add them to `home.packages` in `nvim.nix` or `dev.nix`.

### Package Boundaries

| Level | Location | What goes here |
|-------|----------|----------------|
| **System** | `modules/system.nix` `environment.systemPackages` | Core CLI tools needed before HM loads (`git`, `ripgrep`, `fd`, `fzf`, `zoxide`, `stow`, `ncdu`, `mkalias`) |
| **Home** | `modules/home/*.nix` `home.packages` | User tools, LSPs, formatters, TUI apps, dev stacks |
| **Homebrew** | `modules/darwin.nix` `homebrew.casks` / `brews` | GUI apps, fonts, macOS-only binaries (`lulu`, `ghostty`, fonts) |

**Anti-pattern to avoid**: Putting GUI apps or user-specific dev tools in `environment.systemPackages`. System packages are shared and require `sudo` to change. Home packages are per-user and rebuild faster.

## Theme System

Global theme is a symlink at `.config/themes/current/` → `catppuccin/` or `gruvbox/`. Two files inside (`luacolors.lua`, `shellcolors.sh`) are sourced by Neovim and Zsh respectively. Switch with:

```bash
bash ~/.config/themes/set_theme.sh Catppuccin   # or Gruvbox
```

New theme-aware configs should read from `~/.config/themes/current/` rather than hard-coding palette values.

## Neovim Layout

Lazy.nvim + NvChad-style base46 cache, **leader = `,`**. Entry point `.config/nvim/init.lua`:

- `lua/core/` — core options/keymaps/autocmds
- `lua/plugins/` — main plugin specs loaded by `require("lazy").setup("plugins", ...)`
- `lua/plugins_extra/` — opt-in extras (not auto-loaded)
- `lua/chadrc.lua` — NvChad UI/theme config
- `g:base46_cache` lives at `stdpath("data") .. "/base46_cache/"` — files are `dofile`-d on startup; if highlights look wrong, clear that dir and re-open nvim

**LSP strategy**: Nix provides the binaries (`basedpyright`, `ruff`, `clangd`, `tinymist`, `texlab`, `lua-language-server`, `stylua`). Neovim's `nvim-lspconfig` just enables them via `vim.lsp.enable()`. Mason `ensure_installed` is intentionally empty — do NOT let Mason download tools Nix already provides. Mason is reserved for debug adapters or niche tools not in nixpkgs.

Document-editing keymaps wire into `.local/bin/`:
- `<leader>l` → `~/.local/bin/compiler` (compile current buffer)
- `<leader>p` → `~/.local/bin/opout` (open compiled output)

## Shell Environment

Zsh config at `.config/zsh/.zshrc`. Home-manager sources this file and then appends its own init (starship, fzf-tab, atuin). The `.zshrc` should NOT run `compinit` — HM handles that.

**Key tools:**
- **Starship** prompt — shows git branch, venv, directory. Replaced hand-rolled PS1.
- **atuin** — SQLite shell history, replaces `Ctrl-R`. Run `atuin import auto` once after install.
- **direnv + nix-direnv** — auto-activate `.envrc` on `cd`. `templates/.envrc` has a `uv` venv example.
- **fzf-tab** — fuzzy tab completion for `cd`, file paths, git branches.
- **zoxide** — `cd` replacement with fuzzy memory (`z proj` → `~/Documents/mirror/Work/project`).

**Aliases** (set in `modules/home/core.nix`):
- `cat` → `bat` (syntax-highlighting pager)
- `ls`/`ll`/`la`/`lt` → `eza` with icons and git status
- `v`/`vi`/`vim` → `nvim`

**Functions** (in `.zshrc`):
- `y` — launches `yazi`, cd's shell to yazi's last dir on exit
- `venv <name>` — activates Python venv from `~/Python_Env/<name>`
- `bwunlock` — unlocks `rbw` (Bitwarden Rust CLI) vault

## Dev Toolchain (Python / C / Typst / LaTeX)

All in `modules/home/dev.nix`:
- **Python**: `python312`, `uv`, `ruff`, `basedpyright`, `mypy`
- **C/C++**: `clang-tools` (clangd + clang-format), `cmake`, `ninja`, `lldb`
- **Documents**: `typst`, `tinymist`, `pandoc`, `gnuplot`, `tectonic`, `typstyle`, `poppler-utils`
- **Git**: `gh` (GitHub CLI), `delta` (syntax-highlighting diff pager)
- **Video**: `yt-dlp`

**Quantum SDKs** (`qiskit`, `pennylane`, `cirq`) are NOT installed globally. Install per-project via `uv pip install qiskit` inside a project venv. This avoids dependency conflicts between quantum frameworks.

**Typst workflow**: `typstyle` formats `.typ` files. `tinymist` provides LSP + preview in nvim. `tectonic` compiles LaTeX without a full TeX Live install.

**Python env workflow**:
```bash
cd my-project
uv venv
echo 'source .venv/bin/activate' > .envrc
direnv allow
```

## Privacy & Security Stack

| Tool | Role | Config Location |
|------|------|-----------------|
| **Mullvad DNS** | System-wide encrypted DNS with adblocking | `modules/system.nix` activation script sets `194.242.2.2` / `2a07:e340::2` on all interfaces |
| **dnscrypt-proxy** | Local DNS proxy on `127.0.0.1:5353` with public resolver lists | `modules/system.nix` launchd user agent |
| **rbw** | Bitwarden Rust CLI (~4MB, vs ~80MB official `bw`) | `modules/home/security.nix`; `bwunlock` in `.zshrc` |
| **lulu** | Outbound firewall (Homebrew cask) | `modules/darwin.nix` homebrew casks |
| **syncthing** | P2P file sync, no cloud intermediary | `modules/darwin.nix` launchd user agent; Web UI at `http://localhost:8384` |
| **wireguard-tools** | Terminal WireGuard client | `modules/home/security.nix` |
| **gpg + pinentry-mac** | Git commit signing | `modules/home/security.nix`; signing key must be set manually in git config |

**Design choice**: DNS is set via activation script (runs on every rebuild) rather than manual System Settings. This ensures DNS reverts to Mullvad even after network changes or VPN toggles. `dnscrypt-proxy` runs as a user agent on port 5353 for apps that want a local resolver.

## WM / Bar Trio (macOS-only)

`yabai` (tiling) + `skhd` (hotkeys) + `sketchybar` (bar). Managed as nix-darwin services. If any stops responding after a rebuild or update: **System Settings → Privacy & Security → Accessibility**, toggle the binary OFF then ON.

### Sketchybar Architecture

- **Config**: `.config/sketchybar/sketchybarrc` — bar appearance, item placement, subscriptions
- **Plugins**: `.config/sketchybar/plugins/*.sh` — must be `chmod +x`
- **Space refresh**: `space_refresh.sh` runs on every yabai window/space event. Has a **debounce lock** (`/tmp/sketchybar_space_refresh.lock`) + `sleep 0.15` to batch rapid successive events.
- **Media**: `media.sh` has two modes:
  - **Background listener** (`media.sh listen`): `media-control stream --no-diff` runs persistently, writes state to `/tmp/sketchybar_mediaremote.json`, triggers `media_change` event on changes. This catches browser playback instantly.
  - **Main logic**: reads rmpc/MPD first (priority), then falls back to the state file. Polled every 5s as backup.
- **CPU/RAM**: `cpu_ram.sh` polled every 5s. Shows CPU% and RAM GB.

**Bar style**: Floating pill (`margin=250`, `y_offset=2`, `corner_radius=8`, `shadow=on`). Adjust `margin` for width — smaller = wider bar.

Key skhd bindings (full set in `.config/skhd/skhdrc`): `lalt - {h,j,k,l}` focus, `shift+lalt - {h,j,k,l}` move, `lalt - {1-7}` space, `lalt - q` close, `lalt - d` float, `lalt - t` ghostty, `shift+lalt - space` toggle bar.

## Scripts in `.local/bin/`

Custom utilities (`compiler`, `opout`, `sysact`, `getbib`, `noisereduce`, `shortcuts`, `tag`, `unix`, `zreader`, `booksplt`, `otp`, `weath`). Convention: use `$HOME` or absolute paths, never `~` literals — these are invoked from contexts (incl. `sudo darwin-rebuild`) where `~` may not resolve.

**Cleaned cruft**: Removed ~15 Linux/X11 scripts (dmenuhandler, displayselect, mounter, torwrap, etc.) that were non-functional on macOS.

## Replicating on a New Mac

1. Install Nix: `curl -L https://nixos.org/nix/install | sh`
2. Clone repo to `~/dotfiles` (the `.config` and `.local` here become `$HOME/.config`, `$HOME/.local`)
3. Change `username` in `.config/nix/flake.nix` if not `gravity`; change host attr if not `air`
4. `cd ~/dotfiles/.config/nix && nix run nix-darwin -- switch --flake .#air`
5. After first boot: `atuin import auto`, configure syncthing at `localhost:8384`, open Lulu to approve apps

Linux port: `home.nix` modules are cross-platform; swap `darwinConfigurations` for `nixosConfigurations` and replace yabai/skhd/sketchybar with i3/sway + polybar/waybar.

## How to Modify Common Things

### Add a package
1. **System CLI**: `modules/system.nix` → `environment.systemPackages`
2. **User dev/tool**: `modules/home/dev.nix` or `modules/home/core.nix` → `home.packages`
3. **GUI app/font**: `modules/darwin.nix` → `homebrew.casks` or `homebrew.brews`

### Add a sketchybar plugin
1. Write script in `.config/sketchybar/plugins/myplugin.sh`, `chmod +x`
2. Register in `.config/sketchybar/sketchybarrc` with `--add item`, `--set`, `--subscribe`
3. `pkill sketchybar && sketchybar` to reload

### Change zsh aliases/functions
- Aliases that should be Nix-managed: `modules/home/core.nix` → `programs.zsh.shellAliases`
- Custom functions/complex logic: `.config/zsh/.zshrc`
- After editing `.zshrc`: new shells pick it up automatically

### Change Neovim plugins
- Add/remove specs in `.config/nvim/lua/plugins/` or `.config/nvim/lua/plugins_extra/`
- Never touch `init.lua` — it's the bootstrap and was restored from a backup after HM overwrote it
- Open nvim, run `:Lazy sync` to install/update

### Update flake inputs
```bash
cd ~/.config/nix && nix flake update && sudo darwin-rebuild switch --flake .#air
```

### Update Homebrew packages
```bash
brew update && brew upgrade
```

### Update Neovim plugins
```vim
:Lazy sync
```

## Gotchas

- `.gitignore` excludes `*.env` and `kimi.env` — secrets stay out of the flake. Don't reference env files from `flake.nix`.
- `home-manager.backupFileExtension = "backup"` — collisions leave `.backup` files in `$HOME`; clean them up after resolving.
- Lots of state-y files (`.local/state/nvim/*`, mpd db, darktable db) appear in `git status` constantly; don't commit them.
- **skhd path**: `modules/darwin.nix` reads `../../skhd/skhdrc` via `builtins.readFile`. If you move `darwin.nix`, update this relative path or the flake will fail to evaluate.
- **Mason vs Nix LSPs**: If nvim complains an LSP binary is missing, check `modules/home/dev.nix` first. Do NOT add it to Mason's `ensure_installed` — that defeats the purpose of Nix-managed LSPs.
