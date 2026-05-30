# Adding tools to the manifest

Future-you arriving here because you want to add (or remove) a tool. This
doc walks through the choice tree. Should take 30 seconds for the common
case.

---

## TL;DR — the 30-second version

```yaml
# 1. In manifest.yaml, add a registry entry:
registry:
  oath-toolkit:
    type: brew                       # see "What `type:` do I use?" below
    os: [mac, linux]
    repo: https://www.nongnu.org/oath-toolkit/
    linux_packages:
      apt: oathtool
      dnf: oath-toolkit
      pacman: oath-toolkit

# 2. In the same file, add the name to a profile's packages list:
profiles:
  work:
    packages:
      - snyk
      - oath-toolkit                 # ← here
```

```bash
# 3. Run sync — installs, updates the generated artifacts, done:
./sync
```

That's it. The pattern works for any tool that brew, mise, apt/dnf/pacman,
or a curl installer can install.

---

## What `type:` do I use?

The answer depends on **where the tool lives**, not on your local machine
state.

### Decision tree

```
Is the tool in mise's registry? (run: mise registry <name>)
├── Yes → type: mise
└── No: Is it in brew/cask?     (run: brew info <name>; brew info --cask <name>)
        ├── Yes → type: brew (formula) or type: cask (GUI app)
        └── No: Does the vendor offer a curl installer?
                ├── Yes → type: bootstrap, with `via: "curl ... | sh"`
                └── No: Is it a git repo to clone?
                        ├── Yes → type: git_clone
                        └── No → type: unmanaged (document only; you install by hand)
```

### What this means in practice

**Important: prior install state on YOUR machine doesn't matter.**

`brew install oath-toolkit` works on any mac with brew. The fact that
oath-toolkit is in `brew.sh`'s formula index (the canonical registry of
~6,000 packages, mirrored on every brew install) is what counts. You could
add `htop`, `watchman`, `nmap`, or any other formula you've never touched —
the manifest flow will fetch and install them on demand.

The same is true for:
- mise registry: ~600 tools (`mise registry`)
- Homebrew Cask: ~7,000 GUI apps (`brew search --cask`)
- apt/dnf/pacman: distro-shipped — what your distro's package manager has

You're naming things from a public catalog. Whether you've ever installed
them locally is irrelevant.

---

## When you'd NOT use the manifest

Some tools genuinely don't fit the registry model:

| Situation | Pattern |
|---|---|
| Custom binary you wrote — single file in a github release | `type: bootstrap`, `via: "curl -L https://github.com/.../release/download/v1.0/binary -o ~/.local/bin/foo && chmod +x ~/.local/bin/foo"` |
| A whole repo of code you maintain (e.g. zsh plugins) | `type: git_clone`, with `clone_to:` and optionally `source:` |
| Mac App Store apps (Xcode, Numbers, etc.) | `type: unmanaged`, `via: "mas install 497799835"` (and add `mas` formula to brew) |
| Adobe / proprietary apps installed by their own installers | `type: unmanaged`, `via: "manual: download from adobe.com/..."` |
| Apps pushed by Jamf / corporate MDM | `type: unmanaged`, `via: "Jamf-deployed (IT-managed)"` |
| A python package | NOT in the manifest. Use `uv add <pkg>` per-project, or `uvx <cmd>` for ephemeral CLIs. The manifest only tracks system-level tools. |

`type: unmanaged` is the escape hatch — it's how you DOCUMENT something
the manifest's generator can't install but you still want recorded as
"this should exist on this machine." The generator skips it; you handle
the install by hand.

---

## Concrete examples

### Example 1: Adding a tool already in mise

```yaml
registry:
  ast-grep:
    type: mise
    versions: ["latest"]
    repo: https://github.com/ast-grep/ast-grep

profiles:
  workstation:
    packages:
      - ...
      - ast-grep
```

```bash
./sync   # mise install picks it up
```

### Example 2: Adding a tool in brew (formula)

```yaml
registry:
  htop:
    type: brew
    os: [mac, linux]
    repo: https://htop.dev/
    linux_packages:
      apt: htop
      dnf: htop
      pacman: htop

profiles:
  base:
    packages:
      - htop
```

```bash
./sync
```

### Example 3: Adding a GUI cask (mac only)

```yaml
registry:
  raycast:
    type: cask
    os: [mac]
    repo: https://raycast.com/

profiles:
  workstation:
    packages:
      - raycast
```

### Example 4: Adding a curl-installed tool

```yaml
registry:
  starship-preview:
    type: bootstrap
    via: "curl -sS https://starship.rs/install-preview.sh | sh -s -- -y"
    repo: https://starship.rs

profiles:
  base:
    packages:
      - starship-preview
```

`bootstrap` will run the `via` command on the next bootstrap run.

### Example 5: Adding a git-clone-only tool

```yaml
registry:
  fzf-git:
    type: git_clone
    repo: https://github.com/junegunn/fzf-git.sh
    clone_to: ~/.config/zsh/plugins/fzf-git
    source: ~/.config/zsh/plugins/fzf-git/fzf-git.sh

profiles:
  workstation:
    packages:
      - fzf-git
```

Bootstrap clones it to `~/.config/zsh/plugins/fzf-git`. The `source:` line
tells the zshrc to source the file at shell startup.

### Example 6: Adding a Mac App Store app

```yaml
registry:
  xcode:
    type: unmanaged
    os: [mac]
    via: "mas install 497799835  # Apple's IDE — install via App Store CLI"
    repo: https://developer.apple.com/xcode/
```

You'd then run `mas install 497799835` by hand (one time per machine). The
manifest documents the existence and how to get it.

---

## How do I REMOVE a tool?

Three steps in `manifest.yaml`:

1. Delete the registry entry.
2. Remove from any profile's `packages:` list.
3. Add to `cleanup.yaml` `drop:` list with a category and reason:

```yaml
drop:
  - name: ast-grep
    category: review_dropped
    reason: not used
```

Run `./sync` followed by `./out/uninstall.sh`. The first updates artifacts
to no longer install it; the second uninstalls it from the current machine.

`uninstall.sh` is **profile-independent** — it runs the same drop list on
every machine. You only need to run it once per machine during migration.

---

## What does sync actually DO?

```bash
./sync
```

1. Reads marker files in `~/.config/environment/profile-*` to determine
   which profiles are active on this machine.
2. Resolves the `requires:` chain (e.g., `work → workstation → base`).
3. Runs `generate.py --target <os> --profiles <list>` to regenerate
   `out/*.toml` and `out/Brewfile.*` files.
4. Re-symlinks anything in `home/` into `$HOME` (idempotent — no-ops if
   already symlinked).
5. Concatenates the active profiles' `mise.config.<p>.toml` files into
   `~/.config/mise/config.toml`, runs `mise install`.
6. (Mac only) Runs `brew bundle install --file=Brewfile.<p>` for each
   active profile.

Idempotent. Safe to re-run anytime. Network-bound only when something
new actually needs installing.

---

## The mental model

You're maintaining a **declarative spec** of what should exist on each
profile of machine. Each "thing" in the spec maps to a `type:` that says
which installer can fetch it.

The manifest names tools from public catalogs (brew/mise/distro-pkg/curl/
git). It doesn't matter what's already on your machine — the catalogs are
the source of truth for what exists in the world.

When you sit at a fresh box, the same manifest produces the same end
state. That's the win. That's the whole point.

---

## See also

- `manifest.yaml` — the actual registry + profiles
- `cleanup.yaml` — the drop list
- `design-decisions.md` — why the system is shaped this way
- `decisions.md` — the audit trail of how we got here
