# ~/.config/zsh/.zlogin — runs once per LOGIN shell, after .zshrc.
#
# This is the canonical place for "on login" startup actions. Unlike .zshrc
# (every interactive shell — each tab/split/subshell) and .zshenv (literally
# every zsh invocation, including scripts), .zlogin fires only for login
# shells, so the greeting shows up once when you open a terminal — not on
# every new tab.

# Show a system summary, but only in a real interactive terminal:
#   -o login        → belt-and-suspenders; .zlogin already implies login
#   -o interactive  → skip non-interactive login shells
#   [ -t 1 ]        → stdout is a TTY (skip when output is piped/redirected)
if [[ -z "${FASTFETCH_SHOWN:-}" ]] && [[ -o interactive ]] && [[ -t 1 ]] && command -v fastfetch >/dev/null 2>&1; then
  export FASTFETCH_SHOWN=1
  fastfetch
fi
