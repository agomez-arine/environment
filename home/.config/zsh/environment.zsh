# PATH, EDITOR, XDG_*, ENV_DIR
export PATH="$HOME/.local/bin:$ENV_DIR/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# History (atuin will replace this; keep as fallback)
HISTFILE="$XDG_DATA_HOME/zsh/history"
mkdir -p "$(dirname "$HISTFILE")" 2>/dev/null
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Allow `# comments` in interactive prompt (e.g. paste a script with comments)
setopt INTERACTIVE_COMMENTS
