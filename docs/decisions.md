# Environment Decisions — Audit Trail

> Moved from `manifest.yaml` per Wave 1 schema fix: a declarative state spec
> shouldn't carry historical decisions. Manifest describes WHAT IS; this file
> describes WHY it is that way.

## Schema

- **Domain split:** `manifest.yaml` describes positive state (what should
  exist on a new machine). `cleanup.yaml` describes negative state (what
  should NOT exist on machines being migrated). `decisions.md` (this file)
  is the audit trail — never parsed by the generator.
- **Profile model:** unified `profiles:` block (definition + membership in
  one place). Profiles are additive via `requires:`. `base` is the floor;
  every other profile must `requires: [base]` explicitly. No magic implicit
  base. Marker auto-promotion: setting `profile-work` resolves transitively
  to {base, workstation, work}.
- **Registry model:** keyed by package name. Polymorphic on `type:`
  (mise|brew|cask|bootstrap|git_clone|unmanaged). Validated by Pydantic
  discriminated union (Wave 3).

## Locked tooling decisions

| Topic | Decision |
|---|---|
| `ollama` | drop entirely; clean ~/.ollama/ models manually |
| `kanata` vs `karabiner` | tested 2026-05-29 on work mac. kanata binary works + config valid, BUT Karabiner-VirtualHIDDevice kext install gated by BeyondTrust on work mac. Decision: native macOS Caps→Esc on work mac. Re-test kanata on personal mac when onboarding. |
| `bun` | mise (was brew) |
| `go` | mise (was brew) |
| `postgres` | docker per-project (no global daemon) |
| `rustup` | curl bootstrap (was brew) |
| `tmux` | mise (was brew) |
| `parallel` | mise (was brew) |
| brew system libs | nuked all 4 (imagemagick, cmake, coreutils, luarocks); reinstall on demand |
| OS handling | per-package `os:` tag + `linux_packages` dict |
| zsh plugins | git_clone (cross-platform parity, not brew) |
| claude-code | native curl bootstrap (auto-updates) |
| atuin scope | in mise; NO auto-login; manual `atuin login` per machine |
| machine routing | NO codenames. OS via $OSTYPE; profile markers in `~/.config/environment/profile-<name>` |
| `parallel` correction | actually NOT in mise registry — flipped back to brew. cleanup.yaml records this. |
| `tree`, `tree-sitter-cli`, `wget` | not in mise registry — stay on brew. |
| `btop` (mac) | mise registry says darwin/arm64 unsupported. Stays on brew on mac; could be mise on Linux. |
| `mas`, `snyk`, `git-lfs` | moved brew → mise (verified `mise registry <name>` returns a backend) |
| mise lockfile | tracked at `home/.config/mise/mise.lock` (symlinked to `~/.config/mise/mise.lock`). Regenerate via `mise lock --global`. |
| cleanup workflow | replaced verbose 9-category cleanup.yaml with `verify` (env diff) + `nuke` (single removal script) + slim cleanup.yaml (one-shot migration only) |

## Profile model

- **base** (always implicit via marker=null, but every profile still must `requires: [base]` explicitly)
- **workstation** (requires: [base]) — GUI/heavy-toolchain add-on
- **work** (requires: [workstation]) — corporate add-on
- **personal** (requires: [workstation]) — creative add-on

`requires:` is an AND list. No `requires_any:` until needed.
Generator: `./generate.py --profiles work` resolves to {base, workstation, work} via the requires chain.

## Steady-state counts (informational, not parsed)

- registry_size: 88 packages
- profiles:
  - base: 19 packages
  - workstation: 47 packages
  - work: 15 packages
  - personal: 7 packages
- active set examples:
  - work_mac: base + workstation + work = 81
  - personal_mac_mini: base + workstation + personal = 73
  - fresh_ec2_server: base = 19
  - personal_arch: base + workstation + personal = 73 (some skipped via `os: [mac]`)
- dropped (one-shot per machine, see cleanup.yaml): ~28

## Schema critique applied (Wave 1)

Per Gemini-as-SRE-architect critique:

- Merged `profile_definitions` + `profiles` (cohesion fix; rename now touches one block)
- Made `requires: [base]` explicit (kills the "implicit base" magic)
- Moved `outside:` items into `registry:` as `type: unmanaged` (single source of truth)
- Added `schema_version: "1.0"` at root (forward-compat)
- Moved `decided:` + `steady_state:` to this file (manifest is what-is, not why)
- Normalized all mise versions to lists (`versions: ["latest"]`, never scalar `version:`)
- Flattened `drop:` into a flat list with `category:` field (not nested by category)
- Flattened `cleanup:` into a flat list with `category:` field
- Split `cleanup.yaml` from `manifest.yaml` entirely (positive vs negative state)

## Wave 2 — install correctness (deferred, generator-side)

- Add `creates:` / `check_cmd:` to bootstrappers for idempotency
- Add `commit:` / `branch:` / `tag:` to git_clones for reproducibility
- Generator emits idempotent shell (skip if already installed)

## Wave 3 — Pydantic models (deferred, after waves 1+2)

- `lib/schema.py` with discriminated-union models
- generate.py switches from raw dict access to `Manifest.model_validate(...)`
- Validation errors become structured + actionable
