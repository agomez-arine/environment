
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# Real zshrc. Lives in ~/.config/zsh/ via ZDOTDIR.
# Sourced by the stub at ~/.zshrc.

export ENV_DIR="$HOME/environment"

# ───────── source order is explicit ─────────
source "$ZDOTDIR/environment.zsh"     # FIRST — sets PATH, EDITOR
source "$ZDOTDIR/os-darwin.zsh"       # Homebrew must initialize before mise
source "$ZDOTDIR/tools.zsh"           # mise takes final ownership of tool PATH
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/functions.zsh"
source "$ZDOTDIR/git.zsh"
source "$ZDOTDIR/profile-work.zsh"

# Plugins are cloned by ./sync.
[[ -f "$ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Command-line keybindings (Cmd/Option arrows, word + line motions).
# MUST come after the plugin loader: zsh-autosuggestions and
# zsh-syntax-highlighting both wrap ZLE widgets as they load, so binding first
# would let them re-bind over the top. See the file header for why vi mode
# needs these spelled out.
source "$ZDOTDIR/keybindings.zsh"

# Local overlay (gitignored)
[[ -f "$ENV_DIR/local/zshrc.local" ]] && source "$ENV_DIR/local/zshrc.local"
[[ -f "$ENV_DIR/local/env.local" ]]   && source "$ENV_DIR/local/env.local"

# Kiro CLI shell integration — `post` half. Must be the LAST thing sourced,
# paired with the `pre` half in profile-work.zsh.
if command -v kiro-cli >/dev/null 2>&1; then
  eval "$(kiro-cli init zsh post 2>/dev/null)"
fi


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
