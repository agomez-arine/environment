# linux-only — clipboard shims, debian binary-name shims
command -v xclip >/dev/null && {
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
}

# Cross-platform clipboard: copy/paste.
# If xclip is available, wire them up; otherwise leave a placeholder you can
# replace with your preferred tool (xsel, wl-copy/wl-paste, etc.).
if command -v xclip >/dev/null; then
  alias copy='xclip -selection clipboard'
  alias paste='xclip -selection clipboard -o'
else
  copy()  { echo "copy: no clipboard tool configured on Linux. Edit os-linux.zsh (try: xclip, xsel, or wl-copy)." >&2; return 1; }
  paste() { echo "paste: no clipboard tool configured on Linux. Edit os-linux.zsh (try: xclip, xsel, or wl-paste)." >&2; return 1; }
fi
# Debian binary name drift
command -v fdfind >/dev/null && ! command -v fd  >/dev/null && alias fd=fdfind
command -v batcat >/dev/null && ! command -v bat >/dev/null && alias bat=batcat
