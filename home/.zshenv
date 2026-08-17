# ~/.zshenv — ALWAYS read first, for EVERY shell (login, interactive, script).
# This is the ONLY reliable place to set ZDOTDIR so that login shells spawned
# by terminals like Ghostty/WezTerm/kitty load the real config in ~/.config/zsh
# instead of falling back to the default zsh prompt.
export ZDOTDIR="$HOME/.config/zsh"

# Make mise-managed tools (uv, node, etc.) available to EVERY shell,
# including non-interactive ones that spawn hooks/tools. .zshrc only
# runs `mise activate` for interactive shells, so shims are needed here.
if [[ ":$PATH:" != *":$HOME/.local/share/mise/shims:"* ]]; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi
