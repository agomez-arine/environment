# ~/.zshrc — fallback stub.
#
# Normally NOT used: ~/.zshenv sets ZDOTDIR=~/.config/zsh, so zsh reads
# $ZDOTDIR/.zshrc directly and never sources this file. This stub only runs
# if ~/.zshenv is missing for some reason (e.g. before bootstrap symlinks it),
# so it self-heals by pointing at the real config.
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
[[ -f "$ZDOTDIR/.zshrc" ]] && source "$ZDOTDIR/.zshrc"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
