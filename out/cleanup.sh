#!/usr/bin/env bash
# Generated from cleanup.yaml — do not edit by hand.
# Filesystem cleanup (paths/commands). Idempotent.
# Profiles: base,workstation,work,personal, target OS: mac
set -uo pipefail

echo '=== Cleanup script ==='
echo
BACKUP_LOG="$HOME/.cleanup-log-$(date +%Y%m%d-%H%M%S).txt"
echo "logging to $BACKUP_LOG"

# ───── caches ─────
echo "=== caches ==="
echo "  [nuke] ~/.cache" >> "$BACKUP_LOG"
rm -rf "$HOME/.cache" 2>/dev/null || true  # 9.6GB
echo "  [nuke] ~/Library/Caches" >> "$BACKUP_LOG"
rm -rf "$HOME/Library/Caches" 2>/dev/null || true  # 19GB
echo "  [nuke] ~/Library/Logs" >> "$BACKUP_LOG"
rm -rf "$HOME/Library/Logs" 2>/dev/null || true  # 1.2GB

# ───── stale_dev ─────
echo "=== stale_dev ==="
echo "  [nuke] ~/.nvm" >> "$BACKUP_LOG"
rm -rf "$HOME/.nvm" 2>/dev/null || true  # ~900MB
echo "  [nuke] ~/.haystack-editor" >> "$BACKUP_LOG"
rm -rf "$HOME/.haystack-editor" 2>/dev/null || true  # 844MB
echo "  [nuke] ~/.cursor/Cache" >> "$BACKUP_LOG"
rm -rf "$HOME/.cursor/Cache" 2>/dev/null || true  # ~50MB
echo "  [nuke] ~/.vscode/extensions/.obsolete" >> "$BACKUP_LOG"
rm -rf "$HOME/.vscode/extensions/.obsolete" 2>/dev/null || true  # ~20MB
echo "  [review] ~/.yarn — Confirm migration to pnpm before nuking"  # 1.2GB
ls -lhd "$HOME/.yarn" 2>/dev/null || true
echo "  [nuke] ~/Library/Preferences/com.googlecode.iterm2.plist" >> "$BACKUP_LOG"
rm -rf "$HOME/Library/Preferences/com.googlecode.iterm2.plist" 2>/dev/null || true
echo "  [nuke] ~/Library/Application Support/iTerm2" >> "$BACKUP_LOG"
rm -rf "$HOME/Library/Application Support/iTerm2" 2>/dev/null || true
echo "  [nuke] ~/Library/Saved Application State/com.googlecode.iterm2.savedState" >> "$BACKUP_LOG"
rm -rf "$HOME/Library/Saved Application State/com.googlecode.iterm2.savedState" 2>/dev/null || true
echo "  [review] ~/.conda — Just metadata; safe nuke if fully off conda"
ls -lhd "$HOME/.conda" 2>/dev/null || true

# ───── home_dir ─────
echo "=== home_dir ==="
echo "  [nuke] ~/ssi-row-highlight.png" >> "$BACKUP_LOG"
rm -rf "$HOME/ssi-row-highlight.png" 2>/dev/null || true
echo "  [nuke] ~/ssi-required-aligned.png" >> "$BACKUP_LOG"
rm -rf "$HOME/ssi-required-aligned.png" 2>/dev/null || true
echo "  [nuke] ~/ssi-no-hscroll.png" >> "$BACKUP_LOG"
rm -rf "$HOME/ssi-no-hscroll.png" 2>/dev/null || true
echo "  [nuke] ~/ssi-counter.png" >> "$BACKUP_LOG"
rm -rf "$HOME/ssi-counter.png" 2>/dev/null || true
echo "  [nuke] ~/ssi-flush-final.png" >> "$BACKUP_LOG"
rm -rf "$HOME/ssi-flush-final.png" 2>/dev/null || true
echo "  [nuke] ~/ssi-rows-flush.png" >> "$BACKUP_LOG"
rm -rf "$HOME/ssi-rows-flush.png" 2>/dev/null || true

# ───── shell_files ─────
echo "=== shell_files ==="
echo "  [review] ~/.bash_profile — Owned by root; likely IT setup. You use zsh."
ls -lhd "$HOME/.bash_profile" 2>/dev/null || true
echo "  [review] ~/.zshrc.local — Old per-machine zshrc overlay. Migrated to ~/environment/local/zshrc.local. Safe to nuke after verifying."
ls -lhd "$HOME/.zshrc.local" 2>/dev/null || true

# ───── brew_native ─────
echo "=== brew_native ==="
echo "  [run] brew cleanup -s --prune=all"  # 1-2GB
brew cleanup -s --prune=all || true
echo "  [run] brew autoremove"
brew autoremove || true

# ───── library_deep ─────
echo "=== library_deep ==="
echo "  [review] ~/Library/Containers — Per-app sandbox data. Manually review:
  du -sh ~/Library/Containers/* | sort -hr | head -30
Nuke containers for apps you no longer have.
"  # 54GB-potential
ls -lhd "$HOME/Library/Containers" 2>/dev/null || true
echo "  [review] ~/Library/Application Support — Per-app data. Manually review:
  du -sh ~/Library/Application\ Support/* | sort -hr | head -30
"  # 38GB-potential
ls -lhd "$HOME/Library/Application Support" 2>/dev/null || true

echo "Done. Review log: $BACKUP_LOG"
