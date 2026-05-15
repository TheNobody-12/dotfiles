
# Enable colors:
autoload -U colors && colors
setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.
setopt interactive_comments

# History in cache directory:
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"
setopt inc_append_history

# Load aliases and shortcuts if existent.
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc"

export EDITOR="nvim"
export VISUAL="nvim"

# Completion handled by home-manager; keep styles here
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

zmodload zsh/complist
_comp_options+=(globdots)		# Include hidden files.

eval "$(zoxide init zsh --cmd cd)"
# vi mode
bindkey -v
export KEYTIMEOUT=1

export CLICOLOR=1          # Enable colorized output for ls
export LSCOLORS=ExFxBxDxCxegedabagacad   # Mac/BSD color codes for types (customizable)

alias gdb='gdb-dashboard'


bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes.
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# Use lf to switch directories and bind it to ctrl-o
lfcd () {
    tmp="$(mktemp -uq)"
    trap 'rm -f $tmp >/dev/null 2>&1 && trap - HUP INT QUIT TERM PWR EXIT' HUP INT QUIT TERM PWR EXIT
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bindkey -s '^o' '^ulfcd\n'

bindkey -s '^a' '^ubc -lq\n'

bindkey -s '^f' '^ucd "$(dirname "$(fzf)")"\n'

bindkey '^[[P' delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^[[P' vi-delete-char
bindkey -M vicmd '^e' edit-command-line
bindkey -M visual '^[[P' vi-delete

# Load syntax highlighting; should be last.
if [ -f /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]; then
  source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
elif [ -f /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]; then
  source /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

export PATH="/Library/TeX/texbin:$PATH"


#---Yazi configuration to exit in current folder ---
function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
}

# --- Bitwarden CLI unlock helper (rbw) ---
bwunlock() {
    rbw unlock
}

# --- Python venv Manager ---
function venv() {
    local env_dir="$HOME/Python_Env"
    if [ -z "$1" ]; then
        echo "Available environments in $env_dir:"
        ls -1 "$env_dir" | grep -v "_old"
        return
    fi

    if [ -d "$env_dir/$1" ]; then
        source "$env_dir/$1/bin/activate"
        echo "🐍 Python environment '$1' activated."
    else
        echo "❌ Environment '$1' not found in $env_dir"
    fi
}

# export ZOTERO_API_KEY="..."

# eval "$(/opt/homebrew/bin/brew shellenv)"

#export ZOTERO_READER=zreader

# open any Zotero attachment in zathura
#alias zread='zotcli query "$1" | jq -r '.[0].data.filename' | xargs -I {} nohup zathura "$HOME/Zotero/storage/{}" >/dev/null 2>&1 &'

# open first matching PDF in zathura
# open first matching PDF in zathura (requires research venv)
[ -f ~/claude-code/kimi.env ] && source ~/claude-code/kimi.env

# Kimi for coding alias
alias kimi='source ~/claude-code/kimi.env && claude'
alias ck='source ~/claude-code/kimi.env && claude --agent caveman --agents "$(cat $HOME/dotfiles/.config/claude/agents.json)"'
alias caveman='claude --agent caveman --agents "$(cat $HOME/dotfiles/.config/claude/agents.json)"'
