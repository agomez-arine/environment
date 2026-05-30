# Shell functions

# yazi wrapper: open the file manager and, on quit, cd into the directory you
# were last browsing (press q to quit, Q to quit without cd'ing). This is the
# official wrapper from the yazi docs.
y() {
  command -v yazi >/dev/null || { echo "y: yazi not installed" >&2; return 1; }
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Universal archive extractor
extract() {
  if [[ ! -f "$1" ]]; then
    echo "extract: not a file: $1" >&2
    return 1
  fi
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.zip)            unzip "$1"   ;;
    *.7z)             7z x "$1"    ;;
    *) echo "extract: unknown archive: $1" >&2; return 1 ;;
  esac
}

# Climb up N parent directories (default 1). `up` == `up 1`; `up 0` stays put.
up() {
  local d="" limit=${1:-1}
  for ((i=0; i<limit; i++)); do
    d="../$d"
  done
  builtin cd "${d:-.}"
}

# Generate a UUIDv4, copy to clipboard (mac), and print to terminal
uuid() {
  local id
  if command -v python3 >/dev/null; then
    id=$(python3 -c "import uuid; print(uuid.uuid4(), end='')")
  elif command -v uuidgen >/dev/null; then
    id=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '\n')
  else
    echo "uuid: need python3 or uuidgen" >&2
    return 1
  fi
  if command -v pbcopy >/dev/null; then
    printf '%s' "$id" | pbcopy
  elif command -v xclip >/dev/null; then
    printf '%s' "$id" | xclip -selection clipboard
  fi
  echo "$id"
}
