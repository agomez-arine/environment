# Tool inits — all guarded so a missing tool doesn't break the shell.
#
# Order matters in TWO ways:
#   1. mise must activate FIRST, because it manages (shims) several of the tools
#      below — including starship itself. If starship's `command -v` check runs
#      before mise puts its shim dir on PATH, it short-circuits, starship never
#      initializes, and you're left with /etc/zshrc's default prompt until you
#      `exec $SHELL` (which inherits the now-populated PATH). That was the bug.
#   2. starship's init must run before other tools that hook into the prompt.
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
command -v mise     >/dev/null && eval "$(mise activate zsh)"
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v direnv   >/dev/null && eval "$(direnv hook zsh)"
# fzf ≥0.48 ships its own shell integration via `fzf --zsh` (Ctrl-R history,
# Ctrl-T file widget, Alt-C cd, **<Tab> completion). The old ~/.fzf.zsh file
# is no longer generated, so source the modern integration instead.
command -v fzf      >/dev/null && eval "$(fzf --zsh)"
# atuin MUST init AFTER fzf: both bind Ctrl-R, and last-writer-wins. We want
# atuin to own Ctrl-R (SQLite history w/ cwd/exit-code/duration context +
# encrypted cross-machine sync) while fzf keeps Ctrl-T (file picker), Alt-C
# (cd), and **<Tab> completion. --disable-up-arrow keeps the ↑ key as plain
# shell history (atuin only takes Ctrl-R). The daemon (see config.toml
# [daemon]) keeps a warm in-memory index so atuin's fuzzy search is fzf-fast.
command -v atuin    >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# nvm: REMOVED. mise now manages node (~/.config/mise/config.toml has node = "22.14.0").
# Old nvm init was 2+ seconds of zsh startup. To restore briefly:
#   if [[ -d "$HOME/.nvm" ]]; then
#     export NVM_DIR="$HOME/.nvm"
#     [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
#   fi
# To clean up the disk: rm -rf ~/.nvm  (after verifying mise install of node works)
