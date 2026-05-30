# tmux tips

Custom config at `home/.tmux.conf`. Reload with `prefix + r`.

## Keybindings (prefix = Ctrl+Space)

| Action | Keys | Notes |
|---|---|---|
| **Prefix** | `Ctrl+Space` | Avoids `Ctrl+a` vs nvim conflict |
| Reload config | `prefix + r` | After editing tmux.conf |
| Split horizontal | `prefix + \|` | Opens in current dir |
| Split vertical | `prefix + -` | Opens in current dir |
| New window in current dir | `prefix + c` | (overrides default) |
| Pane navigate | `Ctrl+h/j/k/l` | NO PREFIX — also works in nvim seamlessly |
| Pane resize | `prefix + H/J/K/L` (capital) | hold for repeat |
| Copy mode | `prefix + [` | vi keys: `v` to start selection, `y` to copy to mac clipboard |

## Special features

- **Smart pane navigation**: `Ctrl+h/j/k/l` works for both tmux pane switching AND nvim window navigation. The config detects whether the active pane is running nvim/fzf and routes the keystroke appropriately. Means you don't need separate keybindings on the nvim side.
- **Sessions auto-restore**: tmux-resurrect + tmux-continuum. Sessions persist across reboots. Just open a new tmux and your old layout comes back.
- **Mouse on**: scroll, click panes, drag to resize. Drag-select copies to clipboard.

## Plugins (via TPM)

Loaded from `~/.tmux/plugins/`:
- `tpm` — plugin manager
- `tmux-resurrect` — manual save/restore (`prefix + Ctrl+s` / `prefix + Ctrl+r`)
- `tmux-continuum` — auto-save every 15 min, auto-restore on tmux start
- `tmux-power` — **active** powerline theme (everforest)
- `tmux-gruvbox` — alternate theme, commented out in `.tmux.conf`
- `tmux-cpu` — `#{cpu_percentage}` / `#{ram_percentage}` widgets
- `tmux-battery` — `#{battery_icon}` / `#{battery_percentage}` widgets
- `tmux-online-status` — `#{online_status}` connectivity indicator

To install: open tmux, hit `prefix + I` (capital). Updates: `prefix + U`.

## Status bar

Driven by the **tmux-power** theme (everforest flavor). Switchable to **tmux-gruvbox**
by toggling the commented blocks in `home/.tmux.conf`.

Layout (left → right):
- Left: `[session-name]`
- Window list: themed inactive/active
- Right (inner→outer): `weather  CPU RAM` ▸ `battery online` ▸ `day time · date` ▸ `user@host`

Widgets:
- **Weather** — `home/.config/tmux/scripts/tmux-weather.sh` (wttr.in, cached 15 min).
  Pin a city with `export WTTR_LOCATION="City"`.
- **CPU/RAM/battery** — from the widget plugins listed above.
- **Online** — green globe 󰖟 when connected, red 󰞐 when offline.

**Load order matters**: the theme plugin must be declared BEFORE the widget
plugins (tmux-cpu/battery/online) in `.tmux.conf`. The theme writes the
`#{...}` tokens into status-right; the widget plugins then rewrite those tokens
into live `#(script)` calls. If a widget loads first, its token never exists
and renders empty.

## Troubleshooting

### Online indicator shows a green check mark ✅ instead of the globe

**Cause:** `tmux-online-status` hardcodes `online_icon_osx="✅ "` (a green-check
emoji) as its macOS default, used whenever `@online_icon` is unset *or* when the
running server still has an old cached `#()` render. So even after fixing
`@online_icon`, an already-running tmux server can keep drawing the stale ✅.

**Confirm the config is actually correct (not the cache):**
```sh
# Should show the globe bytes (f3 b0 96 9f = U+F059F), NOT e2 9c 85 (✅):
~/.tmux/plugins/tmux-online-status/scripts/online_status_icon.sh | xxd | head -2
# Should print the @online_icon override, not empty:
tmux show-options -g @online_icon | cat -v
```

**Clear the stale cache (in order of escalation):**
1. `prefix + r` (re-source) — often not enough on its own for cached `#()`.
2. Force a `#()` cache flush by cycling the refresh interval:
   ```sh
   tmux set -g status-interval 1; tmux refresh-client -S; sleep 2; \
   tmux set -g status-interval 5; tmux refresh-client -S
   ```
3. **Guaranteed fix — restart the tmux server.** Sessions auto-restore via
   tmux-continuum, so this is safe:
   ```sh
   tmux kill-server   # closes ALL sessions; continuum restores them on next start
   ```
   (If you have unsaved work in panes, save first: `prefix + Ctrl+s`.)

### A status-bar glyph renders as a box / wrong symbol

The icons are Nerd Font glyphs. Make sure the terminal font is a Nerd Font
(this setup uses Hack Nerd Font in Ghostty). To test a codepoint:
```sh
printf '\U000F059F\n'   # should print the globe 󰖟
```

### Widget shows empty / blank

Usually a load-order problem (see "Load order matters" above) or the widget
plugin wasn't installed. Reinstall with `prefix + I`, then reload.

### `'~/.tmux/plugins/tpm/tpm' returned 1` on reload

Cosmetic. TPM's source-time install check exits non-zero when there's nothing
to do. Not an error.


## Common workflows

### Start a new project session

```sh
tmux new -s myproject
```

### Sessionizer (when implemented in bin/)

A fzf-driven session creator that opens projects in dedicated tmux sessions. Vendored from ThePrimeagen.

Hotkey to add: `bind C-f run-shell "tmux neww $ENV/bin/tmux-sessionizer"`

### Detach + reattach

```sh
prefix + d           # detach (session keeps running)
tmux ls              # see existing sessions
tmux a               # attach to last
tmux a -t myproject  # attach to specific
```

### Kill a runaway pane

```sh
prefix + x           # kill current pane (asks)
```

## Where things live

| File | Purpose |
|---|---|
| `home/.tmux.conf` | The whole config — symlinked to `~/.tmux.conf` |
| `~/.tmux/plugins/` | TPM-managed plugins (cloned, NOT in repo) |
| `~/.tmux/resurrect/` | Saved session state (NOT in repo) |
