# zsh tips

Hybrid layout: `home/.zshrc` is a one-line stub that sources the real config from `home/.config/zsh/.zshrc` (XDG-compliant via `ZDOTDIR`).

## Layout

```
home/.config/zsh/
├── .zshrc                    # entry point — sources fragments in explicit order
├── environment.zsh           # PATH, EDITOR, XDG vars, history settings
├── tools.zsh                 # mise/starship/atuin/zoxide/direnv inits
├── aliases.zsh               # conditional aliases (eza, fd, bat, ...)
├── functions.zsh             # extract, uuid, ...
├── git.zsh                   # gst, gco, gp, gpu, gl, gd, gs, gcm, gsu, gdf
├── os-darwin.zsh             # Homebrew shellenv; runs before mise activation
├── profile-work.zsh          # work environment and Kiro shell integration
└── plugins/                  # git-cloned at bootstrap (NOT in repo)
    ├── zsh-autosuggestions/  # ghost-text completion (gray)
    └── zsh-syntax-highlighting/
```

## Source order is explicit in .zshrc

No numeric prefixes. Read top-to-bottom:

```bash
source $ZDOTDIR/environment.zsh     # FIRST — sets PATH for everything else
source $ZDOTDIR/os-darwin.zsh       # Homebrew first
source $ZDOTDIR/tools.zsh           # mise gets final tool PATH ownership
source $ZDOTDIR/aliases.zsh
source $ZDOTDIR/functions.zsh
source $ZDOTDIR/git.zsh
source $ZDOTDIR/profile-work.zsh

# plugins are loaded after that
```

## Adding an alias

Edit `home/.config/zsh/aliases.zsh` (always-available) or `home/.config/zsh/git.zsh` (git-specific). Open a new shell to pick up the change. Or `source ~/.zshrc` in current shell.

## Adding a function

Edit `home/.config/zsh/functions.zsh`. Same reload pattern.

## Adding a work alias

E.g., something only on the work mac:

```bash
# In home/.config/zsh/profile-work.zsh
alias adev='aws sso login --profile arine-dev'
```

## Local-only overrides

Per-machine secrets, identity, or last-mile tweaks live OUTSIDE the repo:

```
~/environment/local/                # gitignored
├── zshrc.local                     # last lines of .zshrc, after everything else
├── env.local                       # PATH munges, API tokens
└── functions/                      # work-only zsh functions
```

The .zshrc auto-sources these if they exist.

## Shell startup time

Should be ~400ms or under (down from 2.7s when nvm was sourced). To profile:

```sh
zsh -i /tmp/zprof.zsh   # where zprof.zsh has: zmodload zsh/zprof; source ~/.zshrc; zprof
```

If something is slow, the offender shows up at the top.

## Autosuggestions (gray ghost text)

Type any command — the plugin shows a gray completion based on history. Press `→` (right arrow) to accept, or `Ctrl+e` to accept-and-edit.

If you don't see suggestions:
- Make sure you're in a NEW shell (started after plugin clone)
- Check `~/.config/zsh/plugins/zsh-autosuggestions/` exists
- Run `echo $functions[_zsh_autosuggest_start] | head` — should show function body, not "command not found"

## atuin (history)

Better history search:
- `Ctrl+R` — fuzzy search across all history (not just this session)
- Up arrow is DISABLED (we set `--disable-up-arrow` in `tools.zsh`) so it doesn't conflict

To sync history across machines: `atuin login` (per machine, opt-in). Not configured by default.

## starship (prompt)

Config at `home/.config/starship.toml`. Shows: dir, git status, language version (when in a project), AWS profile, etc.

To customize: edit the toml. Live-preview with `starship explain` in any shell.

## Where things live

| File | Purpose |
|---|---|
| `home/.zshrc` | Tiny stub (ZDOTDIR redirect) |
| `home/.config/zsh/.zshrc` | Real entry point |
| `home/.config/zsh/*.zsh` | Sourced fragments |
| `home/.config/zsh/plugins/` | Cloned at bootstrap |
| `~/environment/local/zshrc.local` | Per-machine final overrides |
| `~/.cache/zsh/` | atuin DB, zsh history fallback |
