# environment

My dotfiles + package manifest. Reproducible across mac (work + personal),
Linux (Arch, Fedora, Ubuntu), and headless servers (EC2, Pi).

## SURVIVAL CHEATSHEET (no internet help? start here)

Everything is 5 scripts. You don't need to remember anything else.

```bash
# 1. Get the repo (SSH if keys are set up, else HTTPS — works on a bare box):
git clone git@github.com:agomez-arine/environment.git ~/environment   # with SSH key
git clone https://github.com/agomez-arine/environment.git ~/environment # no key yet
cd ~/environment

# 2. Set up THIS machine (pick one):
./bootstrap --profile server    # headless box / EC2 (base tools, no GUI)
./bootstrap --profile work       # work mac
./bootstrap --profile personal   # personal machine
./bootstrap --minimal            # shell + symlinks ONLY, no installers (fastest)

# 3. Day to day:
git pull && ./sync               # converge to manifest (fast: installs only what's missing)
./upgrade                        # SLOW, opt-in: actually bump versions
./verify                         # report drift (missing / orphan / IT-managed)
./nuke                           # dry-run: show what's installed but NOT declared
./nuke --execute                 # actually remove the undeclared extras
```

Rule of thumb: **`sync` installs, `upgrade` bumps, `nuke` removes, `verify` reports.**
`sync` never upgrades or auto-updates brew — that's why it's fast. Run `./upgrade`
when you actually want newer versions.

## Quickstart on a fresh machine

```bash
# SSH (if your key is already on the box):
git clone git@github.com:agomez-arine/environment.git ~/environment
# OR HTTPS (fresh EC2 / no SSH key yet):
git clone https://github.com/agomez-arine/environment.git ~/environment
cd ~/environment

# Pick the machine type:
./bootstrap --profile work        # work mac (workstation + work add-ons)
./bootstrap --profile personal    # personal machine (workstation + personal)
./bootstrap --profile server      # headless server (base only)
./bootstrap --profile base        # bare minimum

# Or interactive prompt:
./bootstrap

# Or fast SSH path (no installers, just shell + symlinks):
./bootstrap --minimal
```

## Daily use

- **Pull repo updates + converge:** `git pull && ./sync` (fast; installs only what's missing, never auto-updates brew)
- **Upgrade versions (opt-in, slow):** `./upgrade` — runs `brew update && brew upgrade` + `mise upgrade`. Use `./upgrade --dry-run` to preview.
- **Check for drift:** `./verify` — lists MISSING / ORPHAN / IT-MANAGED packages vs the manifest.
- **Remove undeclared extras:** `./nuke` (dry-run) then `./nuke --execute`.
- **Add a tool:** see [`docs/ADDING.md`](docs/ADDING.md) — covers brew, mise, curl-installed, git-cloned, and Mac App Store cases.

## Docs

| File | What's in it |
|---|---|
| [`docs/ADDING.md`](docs/ADDING.md) | How to add (or remove) a tool from the manifest |
| [`docs/tmux.md`](docs/tmux.md) | tmux keybindings + workflows + troubleshooting |
| [`docs/nvim.md`](docs/nvim.md) | LazyVim layout + customization + cheatsheet |
| [`docs/zsh.md`](docs/zsh.md) | zsh fragments + adding aliases/functions + plugin model |
| `manifest.yaml` | What should exist (steady state) |
| `cleanup.yaml` | What should NOT exist (migration only) |

## Layout

```
~/environment/
├── README.md            # this file
├── bootstrap            # one-time setup (curl-installs mise/rustup, symlinks)
├── sync                 # idempotent re-runner (regen out/, brew bundle, mise install)
├── upgrade              # opt-in SLOW path: brew update/upgrade + mise upgrade
├── verify               # report drift: missing / orphan / IT-managed vs manifest
├── nuke                 # inverse of sync: remove what's installed but NOT declared
├── generate.py          # manifest.yaml → out/* (uv-script with inline deps)
├── manifest.yaml        # source of truth: positive state
├── cleanup.yaml         # source of truth: negative state
├── docs/                # tips for tmux, nvim, zsh, manifest editing
├── home/                # mirrors $HOME — symlinked into ~ at bootstrap
├── out/                 # generated artifacts (committed for fresh-box install)
├── docker/              # cross-OS test harness
└── local/               # gitignored per-machine overrides (identity, secrets)
```

## How profiles work

Profiles are additive. The active set on a machine is the union of:
- `base` (always)
- any profile whose marker file exists at `~/.config/environment/profile-<name>`
- any profile transitively reached via `requires:` in `manifest.yaml`

Setting `--profile work` creates the `profile-work` marker. The requires chain
(`work → workstation → base`) is then resolved at install time. One marker,
three profiles activated.

## Cross-OS

| OS | Tested |
|---|---|
| macOS Sequoia | yes (work mac) |
| Ubuntu 24.04 | docker-tested (12/12 scenarios) |
| Fedora 41 | docker-tested |
| Arch Linux | docker-tested |
