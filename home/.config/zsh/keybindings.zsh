# Command-line editing keys. Sourced from .zshrc AFTER the plugin loader so
# nothing downstream can quietly steal these bindings back.
#
# ───────── why this file exists ─────────
# This shell runs in vi mode, and NOT because anything asked for it: zsh selects
# `viins` as the default keymap automatically when $EDITOR or $VISUAL contains
# the substring "vi" — and ours is `nvim` (see environment.zsh). Confirm with:
#
#   bindkey -lL | grep main      # → bindkey -A viins main
#
# That default keymap leaves the macOS-standard motion keys either dead or
# actively harmful. Before this file, in viins:
#
#   ^A  → self-insert     (Cmd+Left inserted a raw control char)
#   ^E  → self-insert     (Cmd+Right, same)
#   ^K  → self-insert
#   \eb → undefined-key   (Opt+Left)
#   \ef → undefined-key   (Opt+Right)
#
# Worse than dead, in fact: with `\ef` unbound, zsh falls back to treating the
# lone ESC as "leave insert mode", so Opt+Right became ESC → vicmd → `f`, which
# is vi-find-next-char. That waits for a target character, so it silently
# swallowed your next keypress and dumped you in normal mode. Opt+Left only
# *seemed* to work for the same reason: ESC → vicmd → `b` (vi-backward-word),
# leaving you stuck in normal mode afterwards.
#
# We bind the sequences explicitly in both keymaps instead of switching to emacs
# mode (`bindkey -e`), so ESC-then-vi-keys command line editing still works.
#
# ───────── what the terminal actually sends ─────────
# Ghostty already emits the right bytes out of the box — no ghostty config
# changes were needed. Verify any time with:
#
#   ghostty +list-keybinds | grep arrow
#
#   Cmd+Left   → text:\x01   (^A)      Cmd+Right  → text:\x05   (^E)
#   Opt+Left   → esc:b       (\eb)     Opt+Right  → esc:f       (\ef)
#
# Opt+arrow depends on `macos-option-as-alt = left` in ~/.config/ghostty/config;
# without it macOS eats Option for composing accented characters. Note that only
# the LEFT Option key acts as Alt — right Option still composes.

# Bind in viins (typing) and vicmd (after ESC) alike, so the motions behave
# identically no matter which vi mode you happen to be in.
for _keymap in viins vicmd; do
  # ── Line motions: Cmd+Left / Cmd+Right, plus bare Ctrl-A / Ctrl-E ──
  bindkey -M "$_keymap" '^A' beginning-of-line
  bindkey -M "$_keymap" '^E' end-of-line

  # ── Word motions: Opt+Left / Opt+Right ──
  bindkey -M "$_keymap" '\eb' backward-word
  bindkey -M "$_keymap" '\ef' forward-word

  # Also accept the CSI-with-modifier forms. Ghostty sends the ESC-prefixed pair
  # above, but tmux (extended-keys on, see ~/.tmux.conf), ssh into other hosts,
  # and iTerm2 can all deliver modified arrows in this style instead. Binding
  # both costs nothing and stops the keys from breaking in those contexts.
  bindkey -M "$_keymap" '^[[1;3D' backward-word     # Opt/Alt + Left
  bindkey -M "$_keymap" '^[[1;3C' forward-word      # Opt/Alt + Right
  bindkey -M "$_keymap" '^[[1;5D' backward-word     # Ctrl + Left
  bindkey -M "$_keymap" '^[[1;5C' forward-word      # Ctrl + Right

  # ── Home / End, in both the CSI and VT-style encodings ──
  bindkey -M "$_keymap" '^[[H'  beginning-of-line
  bindkey -M "$_keymap" '^[[F'  end-of-line
  bindkey -M "$_keymap" '^[[1~' beginning-of-line
  bindkey -M "$_keymap" '^[[4~' end-of-line
  bindkey -M "$_keymap" '^[OH'  beginning-of-line
  bindkey -M "$_keymap" '^[OF'  end-of-line
done
unset _keymap

# A few line-editing keys that every other terminal on the machine has, but
# which viins leaves as self-insert. ^W / ^U are already sane in viins
# (vi-backward-kill-word / vi-kill-line) so they're deliberately left alone.
bindkey -M viins '^K' kill-line            # kill to end of line
bindkey -M viins '^Y' yank                 # paste what was killed
bindkey -M viins '^[^?' backward-kill-word # Opt+Backspace → delete word back

# Delete key (forward delete) in vicmd, where it's otherwise unbound.
bindkey -M vicmd '^[[3~' delete-char

# ───────── ESC ambiguity ─────────
# Opt+arrow arrives as two bytes (ESC then b/f), so after a lone ESC zsh has to
# wait KEYTIMEOUT hundredths of a second to decide: start of an escape sequence,
# or "switch to vicmd"? This is the unavoidable tax of keeping vi mode. The 40
# (0.4s) default makes ESC feel laggy; 20 (0.2s) is snappier and still leaves
# ample room for the terminal to deliver both bytes of a real sequence.
KEYTIMEOUT=20
