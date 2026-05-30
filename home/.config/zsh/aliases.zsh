# Conditional aliases — survive on machines where the binary isn't installed
command -v eza      >/dev/null && alias ls='eza --icons --git'
command -v eza      >/dev/null && alias ll='eza -lh --icons --git'
command -v eza      >/dev/null && alias tree='eza --tree --icons --git'
command -v bat      >/dev/null && alias cat='bat --plain'
command -v fd       >/dev/null && alias find='fd'
# rg replaces grep but only as an alias if the user opts in — many scripts assume `grep` semantics
# command -v rg     >/dev/null && alias grep='rg'
