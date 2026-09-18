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

# Create and activate a disposable environment for an arine_api worktree or PEP 723 script.
tmpvenv() {
  command -v uv >/dev/null || { echo "tmpvenv: uv not installed" >&2; return 1; }

  if (( $# > 1 )); then
    echo "usage: tmpvenv [pep-723-script.py]" >&2
    return 1
  fi

  local root name python script venv tmp_root
  if (( $# == 1 )); then
    script="${1:A}"
    if [[ ! -f "$script" ]]; then
      echo "tmpvenv: script not found: $script" >&2
      return 1
    fi
    python="$(uv python find --script "$script")" || return
    name="${script:h:h:t}-${script:h:t}-${script:t:r}"
  else
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
      echo "tmpvenv: not inside a Git worktree" >&2
      return 1
    }

    local dev_requirements="$root/dev_requirements.txt"
    local app_requirements="$root/layers/arine_api/requirements.txt"
    if [[ ! -f "$dev_requirements" || ! -f "$app_requirements" ]]; then
      echo "tmpvenv: expected arine_api requirement files under $root" >&2
      return 1
    fi

    python=3.10
    name="${root:h:t}-${root:t}"
  fi

  name="${name//[^A-Za-z0-9._-]/-}"
  tmp_root="${TMPDIR:-/tmp}"
  venv="${tmp_root%/}/${name}-$(date +%Y%m%d-%H%M%S)-$$"

  uv venv --python "$python" --prompt "$name" "$venv" || return
  if [[ -n "$script" ]]; then
    VIRTUAL_ENV="$venv" uv sync --script "$script" --active || return
    uv pip install --python "$venv/bin/python" debugpy || return
  else
    uv pip install --python "$venv/bin/python" \
      -r "$dev_requirements" \
      -r "$app_requirements" \
      debugpy || return
  fi

  source "$venv/bin/activate"
  echo "Activated temporary environment: $venv"
}
