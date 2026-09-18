# Work Mac environment.
export AWS_PROFILE=arine-dev
export ARINE_REPO="$HOME/arine-code"
[[ -d "$ARINE_REPO" ]] && alias ad='cd $ARINE_REPO'

# ───────── Kiro CLI shell integration (WORK ONLY) ─────────
# kiro-cli (AWS q/CodeWhisperer rebrand) splits its shell init into `pre` and
# `post`: `pre` opens shell state/hooks, `post` closes them. They MUST be
# sourced separately (concatenating both in one eval yields an `unmatched '`
# because pre opens a block that only post closes). So `pre` runs here and
# `post` runs at the very end of $ZDOTDIR/.zshrc. Guarded + work-scoped so it
# never touches personal/headless boxes. Companion block: KIRO post in .zshrc.
if command -v kiro-cli >/dev/null 2>&1; then
  eval "$(kiro-cli init zsh pre 2>/dev/null)"
fi
