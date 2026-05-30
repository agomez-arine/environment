# ~/.zshenv — ALWAYS read first, for EVERY shell (login, interactive, script).
# This is the ONLY reliable place to set ZDOTDIR so that login shells spawned
# by terminals like Ghostty/WezTerm/kitty load the real config in ~/.config/zsh
# instead of falling back to the default zsh prompt.
export ZDOTDIR="$HOME/.config/zsh"
