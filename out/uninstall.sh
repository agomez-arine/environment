#!/usr/bin/env bash
# Generated from cleanup.yaml — do not edit by hand.
# One-shot uninstall (per machine, during migration).
set -uo pipefail

echo '=== Uninstall (legacy / superseded packages) ==='
brew bundle dump --describe --file="$HOME/.brew-backup-$(date +%Y%m%d-%H%M%S).txt" 2>/dev/null || true

# ─── superseded ───
brew uninstall --ignore-dependencies "oh-my-posh" 2>/dev/null || true  # starship replaces
brew uninstall --ignore-dependencies "pre-commit" 2>/dev/null || true  # lefthook replaces
brew uninstall --ignore-dependencies "pipx" 2>/dev/null || true  # uvx replaces

# ─── redundant_version_manager ───
brew uninstall --ignore-dependencies "pyenv" 2>/dev/null || true  # mise replaces
brew uninstall --ignore-dependencies "tfenv" 2>/dev/null || true  # mise replaces
brew uninstall --ignore-dependencies "tgenv" 2>/dev/null || true  # mise replaces
brew uninstall --ignore-dependencies "nvm" 2>/dev/null || true  # mise replaces. nvm isn't a brew package; ~/.nvm is the dir to nuke.

# ─── gui_redundancy ───
brew uninstall --ignore-dependencies "iterm2" 2>/dev/null || true  # Ghostty is primary
brew uninstall --ignore-dependencies "github-desktop" 2>/dev/null || true  # gh + lazygit replaces

echo 'Running brew autoremove...'
brew autoremove
