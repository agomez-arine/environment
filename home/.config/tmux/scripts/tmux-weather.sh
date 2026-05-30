#!/usr/bin/env bash
#
# tmux-weather.sh — print a compact current-weather string for the tmux status
# bar using wttr.in.
#
# Output looks like:  ☀️ +72°F   (icon + temperature)
#
# Behavior:
#   * Results are cached for $CACHE_TTL seconds so the status bar can redraw
#     frequently without re-hitting the network. wttr.in asks clients not to
#     poll more than a few times per hour.
#   * On any failure (offline, timeout, bad response) it prints the last good
#     cached value if available, otherwise a neutral placeholder so the status
#     bar never shows an error.
#
# Location: wttr.in auto-detects from your IP by default. To pin a city, set
#   WTTR_LOCATION (e.g. export WTTR_LOCATION="Seattle").
#
# Format codes (wttr.in): %c = condition icon, %t = temperature.

set -euo pipefail

CACHE_TTL=900 # 15 minutes
CACHE_DIR="${TMPDIR:-/tmp}"
CACHE_FILE="${CACHE_DIR%/}/tmux-weather.cache"
LOCATION="${WTTR_LOCATION:-}"
FORMAT='%c%t'

# Use cache if it's fresh.
if [[ -f "$CACHE_FILE" ]]; then
  now=$(date +%s)
  # stat is platform-specific (BSD/macOS vs GNU/Linux).
  if mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null); then :; else
    mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  fi
  age=$((now - mtime))
  if (( age < CACHE_TTL )); then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# Fetch fresh data (short timeout so a slow network can't stall the bar).
url="https://wttr.in/${LOCATION}?format=${FORMAT}"
if result=$(curl -fsS --max-time 3 "$url" 2>/dev/null) && [[ -n "$result" ]]; then
  # wttr.in occasionally returns an HTML error page; guard against that.
  if [[ "$result" != *"<"* && "$result" != *"Unknown location"* ]]; then
    # Trim surrounding whitespace.
    result="$(printf '%s' "$result" | tr -s ' ' | sed -e 's/^ *//' -e 's/ *$//')"
    printf '%s' "$result" >"$CACHE_FILE"
    printf '%s' "$result"
    exit 0
  fi
fi

# Failure path: fall back to stale cache, else a placeholder.
if [[ -f "$CACHE_FILE" ]]; then
  cat "$CACHE_FILE"
else
  printf '%s' '󰖐 --'
fi
