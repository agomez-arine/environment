#!/usr/bin/env bash
#
# resurrect-keep-best.sh — protect tmux-resurrect snapshots from being
# clobbered by an "empty start".
#
# THE PROBLEM THIS SOLVES
#   tmux-continuum auto-saves on a timer. If tmux ever starts fresh with only
#   one or two near-empty sessions (e.g. after a `kill-server` where restore
#   didn't repopulate, or a brand-new server), that empty state gets saved and
#   the `last` symlink is repointed to it — overwriting the reference to your
#   real, full snapshot. A later restore then brings back *nothing*.
#
# WHAT THIS DOES
#   Runs as tmux-resurrect's `post-save-all` hook (after every save). If the
#   snapshot that was just written is "tiny" (fewer than MIN_PANES pane lines)
#   AND a larger, recent snapshot exists, it repoints `last` back to that good
#   snapshot. Net effect: an empty auto-save can never destroy your ability to
#   restore a real session set. Normal (non-tiny) saves are left untouched and
#   become the new `last` as usual.
#
#   The tiny snapshot file itself is kept on disk (not deleted) for forensics;
#   only the `last` pointer is protected.
#
# TUNING
#   MIN_PANES — snapshots with at least this many `pane` lines are considered
#   "real" and are always allowed to become `last`. Default 2. Raise it if your
#   normal working set is always larger and you want stronger protection.

set -euo pipefail

MIN_PANES="${RESURRECT_KEEP_BEST_MIN_PANES:-2}"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# Respect an explicit @resurrect-dir override if the user set one.
RESURRECT_DIR="$(tmux show-option -gqv @resurrect-dir 2>/dev/null || true)"
RESURRECT_DIR="${RESURRECT_DIR:-$XDG_DATA_HOME/tmux/resurrect}"

last_link="$RESURRECT_DIR/last"

# Nothing to protect if there's no last pointer yet.
[[ -L "$last_link" || -e "$last_link" ]] || exit 0

# Resolve the file `last` currently points at (the snapshot just written).
current="$(readlink "$last_link" 2>/dev/null || true)"
[[ -n "$current" ]] || exit 0
current_file="$RESURRECT_DIR/$current"
[[ -f "$current_file" ]] || exit 0

count_panes() { grep -c '^pane' "$1" 2>/dev/null || echo 0; }

current_panes="$(count_panes "$current_file")"

# If the just-saved snapshot is healthy, leave everything as-is.
if (( current_panes >= MIN_PANES )); then
  exit 0
fi

# The new snapshot is tiny. Find the most recent OTHER snapshot that is healthy
# and repoint `last` at it so a future restore recovers real sessions.
best=""
while IFS= read -r f; do
  [[ "$f" == "$current_file" ]] && continue
  if (( "$(count_panes "$f")" >= MIN_PANES )); then
    best="$f"
    break
  fi
done < <(ls -t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null)

if [[ -n "$best" ]]; then
  ln -sf "$(basename "$best")" "$last_link"
fi

exit 0
