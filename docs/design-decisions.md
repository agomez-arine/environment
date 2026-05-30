# Locked Design Decisions

> Tracks decisions that have *passed scrutiny and are now load-bearing*.
> Distinct from `decisions.md` (audit trail of all decisions made along
> the way) — this file is the prescriptive subset that future-you should
> NOT relitigate without reason.
>
> Format: each entry has the decision, the rationale (short), and the
> stress-test scenario or critique that validated it.

---

## Decision: Hybrid zsh layout (dax + gcav)

**Locked.** Use a `home/.config/zsh/` directory containing the full zshrc
plus modular fragment files. Top-level `~/.zshrc` is a one-line ZDOTDIR
redirect.

```
home/.config/zsh/
├── .zshrc                  # the real entry point
├── environment.zsh         # PATH, $EDITOR, $ENV_DIR, XDG vars
├── tools.zsh               # mise activate, starship init, atuin, zoxide, fzf
├── aliases.zsh
├── functions.zsh
├── git.zsh                 # git aliases (replaces oh-my-zsh git plugin)
├── os-darwin.zsh           # mac-only
├── os-linux.zsh            # linux-only
├── profile-work.zsh        # only sourced when ~/.config/environment/profile-work exists
├── profile-personal.zsh    # only sourced when ~/.config/environment/profile-personal exists
└── plugins/                # git-cloned zsh plugins live here too
    ├── zsh-autosuggestions/
    └── zsh-syntax-highlighting/
```

**Why:**
- mirrors `$HOME` (dax win — stow-friendly, easy to grok where things go)
- self-contained `zsh/` dir (gcav win — easy to share, easy to grep)
- XDG-compliant via `ZDOTDIR` (gcav)
- plugins live alongside the config (no separate plugin-management dir)

**No numeric prefixes.** Source order is explicit in `.zshrc` line-by-line.
Numbering is cute but adds cognitive load. Explicit `source` calls are
self-documenting.

**Validated by:** dir-stress-test scenarios 1, 2, 8 — gcav's
"share zshrc with friend" scenario was the one place gcav clearly won;
this hybrid captures that win without losing dax's mirror-friendliness.

---

## Decision: Two-script entry points — `bootstrap` and `sync`

**Locked.** Replace the `bootstrap + install + lib/*` split with two
clean entry points at the repo root:

- **`bootstrap`** — one-time-per-machine. Does *everything* needed to take
  a fresh box to a working state. ~80 lines, single file, top-to-bottom
  readable.
- **`sync`** — daily idempotent re-runner. Regenerates `out/`, re-symlinks,
  re-runs `brew bundle install` and `mise install`. ~30 lines.

**No `lib/` directory.** Inline functions in bash. If `bootstrap` breaks,
`cat bootstrap` shows you everything in one read. dax's win on
debuggability (scenario 4) is preserved without giving up the bootstrap
vs install split that gcav got right (scenario 5).

**`bootstrap` modes:**
- `./bootstrap` — interactive: prompts for profile (work/personal/server/base)
- `./bootstrap --profile <name>` — non-interactive (CI, scripts)
- `./bootstrap --minimal` — fast SSH path (just shell + symlinks; no mise/brew)

**`sync` modes:**
- `./sync` — regenerate, symlink, install. Honors existing markers. Fast.

**Validated by:** dir-stress-test scenario 4 (the `lib/*` chain was too
fragmented). User feedback: "I don't understand the touch. The bootstrap
should do everything, install should be a sync."

---

## Decision: Profile marker file is set BY bootstrap, not by hand

**Locked.** Onboarding flow:

```bash
git clone <repo> ~/environment
cd ~/environment
./bootstrap --profile work     # bootstrap CREATES ~/.config/environment/profile-work
                               # AND runs the full setup
```

Or interactively:

```bash
./bootstrap
# > What kind of machine is this? [work/personal/server/base/cancel]
# > work
# (creates marker, proceeds)
```

After this, `sync` reads the marker file as the source of truth. The
marker file is the persistent state; the flag is just how `bootstrap`
populates it.

**Why:** The original `touch ~/.config/environment/profile-work &&
./bootstrap` was two steps. Folding the marker creation into `bootstrap`
removes friction without losing the per-machine routing model.

---

## Decision: Fast SSH path via `bootstrap --minimal`

**Locked.** Headless servers / fresh EC2 / Pi don't need mise, brew,
rustup, claude-code, etc. They want shell + tmux + git in 10 seconds.

```bash
ssh server
git clone <repo> ~/environment
~/environment/bootstrap --minimal
```

Does:
1. Symlink `home/` into `$HOME` (just shell + tmux + git config)
2. Clone zsh plugins (small, fast)
3. Skip everything else

**Why:** dax's three-command SSH onboarding is a real win; your
full bootstrap is too heavy for "I just want my shell." `--minimal`
restores that ergonomic without forcing a separate codepath.

**Validated by:** dir-stress-test scenario 9.

---

## Decision: Per-machine notes live in `local/README.md` (gitignored)

**Locked.** Notes about *this specific machine* (BeyondTrust quirks, work
docking station, "I had to file IT ticket #123 to install Karabiner")
go in:

```
local/
├── README.md              # human notes about THIS machine — gitignored
├── zshrc.local
├── gitconfig.local        # identity (email, signing key)
└── env.local              # API tokens
```

**Not** a separate `notes/<hostname>.md` directory.

**Why:**
- Per-machine notes are inherently per-machine (gitignored)
- `local/` is already the bucket for everything per-machine
- One look at `local/` tells you everything machine-specific
- Eliminates the empty `notes/` dir cluttering the tree

**Validated by:** dir-stress-test scenario 12 + user feedback: "Notes
should be colocated and not in a notes dir."

---

## Decision: Domain-split schema (manifest + registry) — kept

**Locked but watched.** The manifest.yaml has profiles + registry split.
Stress test showed it's a wash for solo daily use, but the sunk cost is
real (generator + validator already exist) and it wins on:
- shared package metadata (slack across multiple profiles)
- registry-as-dictionary queries ("what does opencode do?")
- multi-machine state introspection

**Re-evaluation trigger:** if at month 6 you find yourself constantly
running `./generate.py` just to ask "what's installed where?", flatten
back to inline. The schema is small enough that a one-time migration
is feasible.

**Validated by:** six-month-stress-test.md scoring (5 wins, 5 losses,
5 ties). Not a slam-dunk; not a regret either.

---

## Decision: `home/` mirrors `$HOME` exactly (dax pattern)

**Locked.** Configs live at `home/.zshrc`, `home/.config/nvim/`,
`home/.config/zsh/`, `home/.tmux.conf`, etc. The path inside the repo
is the path inside `$HOME`.

**Why:**
- One mental model. To find a config, just know its path under `$HOME`.
- Stow becomes a one-line install (no per-config `ln -s` logic).
- Adding a new tool = `mkdir home/.config/<tool>; cp config there`. Done.
  No install-script update needed.
- Matches `~/.config/<tool>` XDG convention.

**Validated by:** dir-stress-test scenarios 1, 6.

---

## Decision: `cleanup.yaml` separate from `manifest.yaml`

**Locked.** Migration-only state (drops, filesystem cleanup) lives in
`cleanup.yaml`, never in `manifest.yaml`.

**Why:**
- `manifest.yaml` describes *steady state* — what should exist on every
  new machine going forward.
- `cleanup.yaml` describes *one-time-per-machine migration state* — what
  should not exist anymore. Once a machine is fully cleaned, the file
  is irrelevant for that machine.
- Mixing them obscures intent: "is this a new install or a one-time
  migration step?"

**Validated by:** Wave 1 schema critique. User feedback: "everything
that has to do with removing and cleanup lets put in a cleanup yaml."

---

## Decision: NO machine codenames

**Locked permanently.** Machines are referenced by their real `$HOSTNAME`
or by what they ARE (work mac, personal mac, headless server). No
grey/yellow/green/brown/black. No coffee types. No Star Trek ships.

**Why:** every codename forces a name-lookup table that future-you has
to memorize. Marker files describe roles directly.

**Validated by:** repeated user feedback. Documented in
`feedback_no_machine_codenames` memory.

---

## Open / Watched

The following are NOT locked yet — keeping eyes on them:

- **Wave 2 idempotency primitives** (`creates:` / `check_cmd:` on
  bootstrappers, `commit:` / `tag:` / `branch:` on git_clones).
  Deferred until first real install reveals which packages need it.
- **Pydantic schema (Wave 3).** Useful but optional. Add when the YAML
  starts breaking silently.
- **Stow vs hand-rolled symlinks.** Hand-rolled today (matches dax's
  pattern). Stow is a 1-line replacement when wanted.
- **`out/` committed vs gitignored.** Currently TBD. Committed = `brew
  bundle` works on a fresh box without uv/python. Gitignored = cleaner
  repo. Decide before Phase 0 ships.
