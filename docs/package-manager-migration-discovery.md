# Package Manager Migration Discovery

> Historical pre-migration audit. Paths describing the former manifest and
> generator refer to repository history; the direct-config migration removed
> those components.

**Date:** 2026-09-18
**Scope:** Homebrew Bundle, Homebrew Cask isolation, mise configuration and lifecycle behavior, and the proposed policy of using mise for nearly all developer CLIs and Homebrew Cask for macOS GUI applications.
**Source policy:** Primary and official sources only: Homebrew documentation/source, mise documentation/source links, Git LFS documentation, and this repository's own files.

## Executive conclusion

The hybrid direction is sound, with a narrower rule than "mise for every CLI":

> Prefer mise for versioned, self-contained developer executables when a tested backend supplies the required platform artifact and adequate lock/verification metadata. Keep Homebrew formulae or the native OS package manager for host libraries, headers, services, and CLIs whose mise backend is absent, platform-incomplete, or operationally weaker. Use Homebrew Cask for user-approved macOS GUI delivery, not as a sandbox.

The main findings are:

1. Homebrew Bundle fully supports formulae and casks, but it has no documented first-class include/profile system and deliberately has no Brewfile lockfile. Multiple `--file` invocations are a valid additive installation mechanism, but cleanup must operate on the complete active union, not one profile at a time.
2. Homebrew Cask cannot generally be safely sandboxed. Casks install trusted vendor artifacts; `.pkg` and installer-script artifacts are explicitly outside the cask sandbox and may elevate. `appdir: "~/Applications"` changes the destination and can avoid an `/Applications` permission barrier for simple app artifacts, but it is not an isolation boundary.
3. mise has a real global config, hierarchical config merging, named and multiple config environments, project/global lockfiles, strict locked installs, and dry-run support. It does not have a profile dependency graph equivalent to this repository's `requires:` model, so the repository must still resolve `work -> workstation -> base` itself or select all required mise environments explicitly.
4. A mise lockfile is backend-dependent and is not strict merely because `lockfile = true` is set. `mise install --locked`, `MISE_LOCKED=1`, or config-root policy is required to fail on incomplete lock data. Some backends only lock versions; strict artifact URL locking explicitly exempts asdf, several language package backends, Rust, and other installers.
5. mise pruning is based on all tracked config files, not solely the current global manifest. It is useful but not a direct replacement for this repository's active-profile diff. It has a safe dry run and should be previewed before deletion.
6. mise is primarily a development-tool manager, not a host library manager. It can coordinate declared installation prerequisites and has isolated Conda/pkgx backends, but those do not replace Homebrew/apt/dnf/pacman ownership of libraries such as Cairo, `pkg-config`, OpenSSL, graphics/PDF libraries, drivers, and system services.
7. The current repository is already close to the recommended split, but its documentation and scripts overstate Homebrew's no-upgrade guarantee, refer to a nonexistent Brewfile lockfile, do not enforce strict mise locks, do not explicitly perform the advertised mise prune step, and do not install the declared `linux_packages` metadata.

## Repository design inspected

The current design has a coherent central model:

| Area | Current repository behavior | Evidence |
|---|---|---|
| Source of truth | `manifest.yaml` owns profile membership and a typed package registry. | [`manifest.yaml`](../manifest.yaml) |
| Profiles | Marker files select additive profiles; `work` requires `workstation`, which requires `base`. | [`manifest.yaml`](../manifest.yaml), [`sync`](../sync) |
| Generation | `generate.py` emits one mise TOML and Brewfile per profile. | [`generate.py`](../generate.py) |
| mise activation | `sync` concatenates active profile tool entries into `~/.config/mise/config.toml`, then runs `mise install`. | [`sync`](../sync) |
| Brew activation | On macOS, `sync` runs `brew bundle check` and then `brew bundle install --no-upgrade` separately for each active Brewfile. | [`sync`](../sync) |
| Locking | A global `mise.lock` is committed under `home/.config/mise`; generated config enables `lockfile = true`. | [`home/.config/mise/mise.lock`](../home/.config/mise/mise.lock), [`generate.py`](../generate.py) |
| Removal | `verify` computes missing/orphan/duplicate state; `nuke` defaults to preview and does not remove orphan casks unless explicitly requested. | [`verify`](../verify), [`nuke`](../nuke) |
| Managed Mac constraints | IT/MDM-owned casks are omitted from Brewfiles; selected casks use `~/Applications`. | [`generate.py`](../generate.py), [`manifest.yaml`](../manifest.yaml) |

This central manifest provides one place for cross-OS package identity,
unmanaged/MDM visibility, profile dependencies, and installer routing. Those
benefits have a material maintenance cost: profile closure is duplicated in
several scripts, generated output can go stale, and some declared backends are
never executed. Direct Brewfiles and mise configs can replace it if the scope
is narrowed deliberately and unmanaged software is kept in documentation.

## Work Mac package and state audit

The active `work` profile resolves to 94 declared packages:

| Ownership | Count | Result |
|---|---:|---|
| mise developer tools | 48 | Already installed through mise on this Mac. |
| Homebrew Cask GUI/font packages | 7 | Appropriate for Cask. |
| Homebrew formula/native exceptions | 8 | Keep outside mise. |
| Vendor/bootstrap packages | 4 | mise itself, Claude Code, and two zsh plugins need explicit bootstrap handling. |
| MDM/unmanaged packages | 23 | Must remain outside Homebrew ownership. |
| Questionable entries | 4 | Resolve before treating the current manifest as a clean migration source. |

The questionable entries are:

- `disk-inventory-x`: Homebrew disabled the cask on 2026-09-01 because it does
  not pass Gatekeeper. It cannot be reproduced on a fresh Mac from the current
  Brewfile.
- `tree-sitter-cli`: mise now exposes it under the registry key `tree-sitter`.
  It can move from a Homebrew formula after a smoke test.
- `sesh`: an Aqua package exists, but the installed mise registry has no
  shorthand mapping. Keeping the Homebrew formula is the lower-maintenance
  choice unless the direct mise config deliberately names an Aqua backend.
- `kiro-cli`: it is a legitimate cask that installs `Kiro CLI.app` and its CLI.
  mise has an Aqua mapping, but version discovery currently does not resolve
  `latest`; retaining the cask also preserves the app/updater integration.

The current machine is already a useful partial canary for the proposed model:
all 48 intended mise tools are installed, and an interactive shell resolves
most of them from mise. Four important commands are still shadowed by older
paths:

| Command | Active command | Intended mise command |
|---|---|---|
| `terraform` | `/opt/homebrew/bin/terraform` (`1.14.3`, managed through legacy `tfenv`) | mise `1.15.5` |
| `terragrunt` | `/opt/homebrew/bin/terragrunt` (legacy `tgenv`) | mise `1.0.6` |
| `shellcheck` | `/opt/homebrew/bin/shellcheck` | mise `0.11.0` |
| `pnpm` | `/opt/homebrew/bin/pnpm` (`10.12.4`) | mise `11.5.0` |

`mise doctor` reports the cause: `/opt/homebrew/bin` precedes the mise tool
paths. The shell loads `mise activate` and then later evaluates `brew shellenv`,
which moves Homebrew back in front. Package removal would hide this bug rather
than fix it; Homebrew initialization must occur before mise activation.

The current drift reports also contain false positives and genuine legacy
state:

- `verify` reports `cairo` and `pkg-config` missing because it compares against
  `brew leaves`; both are installed as dependencies (`pkg-config` is provided
  by the `pkgconf` formula). `brew bundle check --no-upgrade` correctly reports
  all active Brewfiles satisfied.
- Ten top-level Homebrew formulae are outside the manifest, including
  `pyenv`, `tfenv`, and `tgenv`. Three mise identities are outside it,
  including two names for `git-filter-repo`.
- Claude Code is installed as a Homebrew cask while the manifest declares the
  vendor bootstrap. One owner must be selected.
- The global mise config contains `git-filter-repo`, but the manifest does not.
  Regeneration can therefore erase an intentional local tool.
- `mise lock --global --dry-run` would rewrite platform records and prune a
  stale `actionlint` entry. Strict locked install succeeds for the currently
  installed toolset, but the committed lock is not cleanly derived from the
  manifest.
- Git LFS is correctly initialized in global Git configuration despite the
  bootstrap not declaring that post-install step.
- The machine has only 6.9 GiB free. A local macOS VM or broad parallel
  reinstall is unsafe until space is reclaimed; an ephemeral CI runner is the
  appropriate fresh-install test environment.

Three declared PDF/image formulae (`imagemagick`, `poppler`, and `ghostscript`)
are not assigned to an active profile even though manifest comments describe
them as Neovim dependencies. They are installed today through legacy Homebrew
state. The direct Brewfile must either own them explicitly or the comments and
dependent editor feature must be removed.

## Homebrew Bundle findings

### Formulae and casks

Homebrew Bundle supports both `brew "name"` formula entries and `cask "name"` cask entries. It also supports taps and several other ecosystems. A bundle install installs missing entries and, by default, upgrades outdated entries. `--no-upgrade` suppresses the explicit upgrade phase, but Homebrew warns that `brew install` may still upgrade a dependency when required. Therefore, this repository's statement that `sync` "never upgrades" is stronger than Homebrew guarantees; "does not intentionally upgrade, but dependency resolution may require it" is accurate. [Homebrew Bundle documentation](https://docs.brew.sh/Brew-Bundle-and-Brewfile) [Homebrew version-locking guidance](https://docs.brew.sh/Versions#locking-installed-formulae-at-specific-versions)

The current combination of `HOMEBREW_NO_AUTO_UPDATE=1`, `HOMEBREW_NO_INSTALL_UPGRADE=1`, and `brew bundle install --no-upgrade` is a reasonable low-churn sync policy. It is not a reproducible version pin and cannot promise zero transitive upgrades. [Homebrew version-locking guidance](https://docs.brew.sh/Versions#locking-installed-formulae-at-specific-versions)

### Includes and profiles

Homebrew documents Ruby conditionals inside a Brewfile and arbitrary Ruby evaluation, including OS-specific declarations. It documents keeping multiple snapshots with distinct `--file` paths. It does not document a profile model, profile inheritance, or an include directive. The current Bundle DSL directly defines `brew`, `cask`, `tap`, `cask_args`, and registered extension methods; it has no first-class `include` or `profile` entry. [Advanced Brewfiles](https://docs.brew.sh/Brew-Bundle-and-Brewfile#advanced-brewfiles) [Homebrew Bundle DSL source](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/dsl.rb) [Brewfile path/source handling](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/brewfile.rb)

Consequences for this repository:

- Per-profile Brewfiles plus repeated `brew bundle --file=...` installation are supported and fit the additive profile model.
- Ruby `eval`/file-loading tricks could emulate includes because Brewfiles are Ruby, but they are not a documented Bundle abstraction and would couple the design to implementation details.
- A generated single active Brewfile would simplify checking and cleanup, but is not required for installation.
- Homebrew does not understand `requires:`. The repository must continue resolving profile closure.

### Lock behavior

Homebrew explicitly states that it is a rolling-release package manager and that `brew bundle` "does not and will not" have a Brewfile lockfile. `--no-upgrade`, `brew pin`, and suppressed metadata updates reduce churn but do not create a portable exact lock. [Homebrew Bundle versions](https://docs.brew.sh/Brew-Bundle-and-Brewfile#versions) [Homebrew formula version guidance](https://docs.brew.sh/Versions#locking-installed-formulae-at-specific-versions)

Repository implication: `HOMEBREW_BUNDLE_NO_LOCK=1`, the `Brewfile.lock.json` ignore entry, and comments saying Bundle would write such a lock describe behavior that current Homebrew does not support. They should not be part of the migration's correctness model.

### Check and dry-run behavior

`brew bundle check` is read-only and reports whether dependencies are satisfied. With `--verbose` it lists unmet dependencies. By default, "satisfied" includes up-to-date checks; `--no-upgrade` limits that check when the desired operation is missing-only installation. [Homebrew Bundle check](https://docs.brew.sh/Brew-Bundle-and-Brewfile#brew-bundle-check) [Bundle check source](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/subcommand/check.rb)

There is no documented `brew bundle install --dry-run`. `brew install --dry-run` exists, but Bundle does not expose it as an install option. Practical previews are therefore:

| Intended change | Best official preview | Limitation |
|---|---|---|
| Install missing entries only | `brew bundle check --no-upgrade --verbose` | Reports unmet entries, not an exact command/change plan. |
| Upgrade | `brew outdated` | Reports outdated formulae/casks; self-updating and `version :latest` casks have special rules. |
| Remove undeclared Bundle entries | `brew bundle cleanup` without forcing and decline the prompt | This is a preview/confirmation workflow, not an unconditional dry-run flag; accepting the prompt performs removal. |
| Cache/old-version cleanup | `brew cleanup --dry-run` | This is separate from declarative Bundle cleanup. |
| Orphan dependencies | `brew autoremove --dry-run` | Only formulae no longer needed as dependencies. |

Sources: [Homebrew man page](https://docs.brew.sh/Manpage#bundle-subcommand), [Bundle cleanup source](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/subcommand/cleanup.rb).

The repository's custom `nuke` command is a safer user interface for this design because it is unconditionally preview-only by default and excludes casks unless opted in.

### Cleanup behavior and profile hazard

`brew bundle cleanup` removes supported installed dependencies absent from the selected Brewfile. It can clean formulae, casks, taps, and supported extension types; `--force` performs the removals. For casks, optional `--zap` can remove associated user files and may remove shared files. Bundle keeps formula dependencies required by retained formulae/casks. [Homebrew man page](https://docs.brew.sh/Manpage#bundle-subcommand) [Bundle cleanup implementation](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/subcommand/cleanup.rb)

Running cleanup against `Brewfile.base`, then `Brewfile.workstation`, would make each file treat the other profile's top-level entries as undeclared. Cleanup must instead receive one Brewfile containing the complete active profile union, or remain implemented by a manifest-aware tool such as `nuke`.

This distinction is load-bearing:

- Multiple profile files are safe for additive `check`/`install`.
- Multiple profile files are unsafe as independent desired states for `cleanup`.
- `brew cleanup` and `brew autoremove` are not substitutes for `brew bundle cleanup`; they remove stale artifacts/versions and unneeded dependency formulae, respectively, not every undeclared top-level package.

## Can casks be safely sandboxed?

No, not as a general migration guarantee.

Homebrew's official cask model says installation artifacts are treated as trusted vendor installation actions. `app`, `pkg`, and installer artifacts may write outside the Caskroom through Homebrew moves, macOS installer services, or vendor code. `installer script:` is not sandboxed; `.pkg` artifacts run through macOS `/usr/sbin/installer` and are not run in the cask sandbox. Some need `sudo`. [Cask artifact trust and sandboxing](https://docs.brew.sh/Cask-Cookbook#cask-artifact-trust-and-sandboxing) [Homebrew cask security model](https://docs.brew.sh/Homebrew-Security-and-Supply-Chain#casks-have-a-different-trust-model)

Homebrew does apply meaningful controls: official macOS casks must pass Gatekeeper checks, downloads retain quarantine so macOS checks signatures/notarization, and ordinary cask metadata is reviewed. Homebrew is explicit that these controls do not certify that an application is harmless. A cask checksum proves byte consistency with reviewed metadata, not that the vendor binary is trustworthy. Some casks use `sha256 :no_check`, and self-updating apps can replace themselves outside Homebrew. [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks#platform-compatibility-and-macos-security-protections) [Homebrew cask security model](https://docs.brew.sh/Homebrew-Security-and-Supply-Chain#casks-have-a-different-trust-model)

The following mechanisms must not be confused with cask isolation:

- `cask "kiro", args: { appdir: "~/Applications" }` changes where an `app` artifact is moved. It can avoid a managed `/Applications` write gate, but it does not constrain the app or vendor installer after installation. [Advanced Brewfile cask arguments](https://docs.brew.sh/Brew-Bundle-and-Brewfile#advanced-brewfiles)
- Homebrew's build sandbox protects formula builds/fetch/post-install/test operations, not arbitrary cask installers or applications. [Homebrew supply-chain sandboxing](https://docs.brew.sh/Homebrew-Security-and-Supply-Chain#sandboxing)
- `brew bundle exec --sandbox` isolates a command run inside a Bundle environment. It does not sandbox cask installation or normal GUI launches. [Homebrew man page](https://docs.brew.sh/Manpage#bundle-subcommand)
- Apple's App Sandbox restricts an app according to entitlements in that app; it is not a wrapper Homebrew can apply to an arbitrary signed GUI application. [Apple App Sandbox documentation](https://developer.apple.com/documentation/security/app-sandbox)

The repository is correct to exclude IT/MDM-managed applications rather than trying to adopt or overwrite them. Homebrew Bundle's cask path attempts `--adopt` for a missing cask unless force is used, so an application that exists outside Homebrew can still trigger ownership/adoption behavior. [Homebrew Bundle cask source](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/cask.rb)

## mise findings

### Direct and global configuration

mise's global config is `~/.config/mise/config.toml`; `mise use --global` writes personal defaults there. `MISE_GLOBAL_CONFIG_FILE` can select another global path. Project files override global defaults, and mise merges configuration found from the current directory through its parents. Tool declarations are additive, with a more specific declaration replacing the same tool. [mise configuration](https://mise.jdx.dev/configuration.html) [mise dev tools](https://mise.jdx.dev/dev-tools/)

This supports two valid repository designs:

1. Continue generating one active global `config.toml`, as `sync` does now.
2. Generate native global fragments/environment files and select the profile set through mise.

The first is simpler and keeps `manifest.yaml` authoritative. The second gives mise clearer file ownership and environment-specific lockfiles, but does not eliminate profile resolution.

### Multiple configs and profile options

mise provides several composition mechanisms:

| Mechanism | Behavior | Fit here |
|---|---|---|
| Config hierarchy | Global, parent, project, and local files merge by precedence. | Good for project overrides of machine defaults. |
| `conf.d/*.toml` | All non-hidden fragments load alphabetically by default. | Good for unconditional modular global config; not inherently a profile selector. |
| Named config environments | `MISE_ENV=work`, `mise -E work`, or `.miserc.toml` loads `config.work.toml` globally and `mise.work.toml` in projects. | Good for machine/profile overlays. |
| Multiple environments | `mise -E workstation,work` loads both; the last wins on conflicts. | Can express the resolved active set. |
| Local variants | `mise.local.toml` and environment-local files override shared files and are intended to be uncommitted. | Suitable for machine-only overrides, not shared profile definition. |
| OS restrictions | A tool can declare `os = [...]`; optional automatic platform environments can load OS/architecture files. | Could reduce generator-side OS filtering, but `auto_env` is version-sensitive and currently opt-in. |

Sources: [mise configuration](https://mise.jdx.dev/configuration.html), [mise config environments](https://mise.jdx.dev/configuration/environments.html), [mise dev-tool OS restrictions](https://mise.jdx.dev/dev-tools/#os-specific-tools).

mise does not declare that one config environment requires another. Selecting only `work` will not infer `workstation` and `base`. The repository's marker and `requires:` closure remains necessary; it could export `MISE_ENV=workstation,work`, or generate a fully resolved active file.

Environment-specific configs get separately scoped lockfiles, while tools from the base config remain in the base lock. This is a cleaner match for reusable profile layers than repeatedly replacing one global config and one superset lock, but it increases the number of committed files and requires every invocation to select the same environment list. [mise environment-specific lockfiles](https://mise.jdx.dev/dev-tools/mise-lock.html#environment-specific-lockfiles)

### Lockfiles

`mise.toml` records accepted version requests; `mise.lock` records concrete resolutions. Supported backends can additionally record platform artifact URLs, checksums, and provenance. Global tools require `mise lock --global`; plain `mise lock` targets the active project root. Locked installation can still require network and authentication. [mise lockfile documentation](https://mise.jdx.dev/dev-tools/mise-lock.html)

Important distinctions:

- `lockfile = true` creates/maintains project lockfiles and causes existing locks to be read. It does not by itself require complete artifact entries.
- `mise install --locked`, `MISE_LOCKED=1`, `settings.locked = true`, or `[tool_config] locked = true` enables fail-closed behavior for the applicable scope.
- Strict URL checks skip backends that cannot provide portable artifact URLs, including asdf, Cargo, gem, Go, npm, PyPI/pipx, ubi, core Rust, core Swift, and some others. Some have separate dependency-graph checks; others are version-only.
- Download-oriented backends such as Aqua/GitHub can record artifact metadata when the tool and release expose it.
- A lockfile is a trust input. It can allow reuse of previously verified provenance; `locked_verify_provenance` or paranoid mode requests re-verification for supported backends.
- `minimum_release_age = "7d"` applies mainly to fuzzy requests whose backend reports timestamps. Exact pins, versions selected from a lock, and versions without timestamps are not generally delayed.

Sources: [mise lockfile strict mode and backend support](https://mise.jdx.dev/dev-tools/mise-lock.html#strict-lockfile-mode), [mise lockfile backend support](https://mise.jdx.dev/dev-tools/mise-lock.html#backend-support), [mise security](https://mise.jdx.dev/security.html), [mise minimum release age](https://mise.jdx.dev/configuration/settings.html#minimum_release_age).

Repository implications:

- The current `sync` runs `mise install`, not `mise install --locked`; missing lock data may be resolved rather than rejected.
- A single global lock shared by machines with different active profiles needs deliberate generation for the complete intended profile/platform matrix. Updating it from only the current active global config can leave a stale superset in merge mode or omit another profile in a complete-generation workflow.
- The inspected lock contains entries such as `actionlint` and `git-filter-repo` that are not in the current manifest, demonstrating that lock content and desired package membership are separate concerns. A lockfile must not be treated as the package manifest.
- The current lock also shows heterogeneous backend strength: most tools use Aqua, while `eza` is recorded through asdf and Neovim through vfox. Backend-specific guarantees must be assessed rather than inferred from the common `type: mise` label.

### Dry-run behavior

mise has direct dry-run support for the relevant lifecycle commands:

| Command | Official preview behavior |
|---|---|
| `mise install --dry-run` | Shows what would be installed. |
| `mise install --dry-run-code` | Same preview, exits 1 when work exists; useful in scripts. |
| `mise use --dry-run` | Shows config and installation changes without applying them. |
| `mise upgrade --dry-run` | Shows upgrades without applying them. |
| `mise lock --dry-run` / `mise lock --bump --dry-run` | Shows lock changes without writing. |
| `mise prune --dry-run` | Shows versions that would be deleted. |
| `mise uninstall --dry-run` | Shows requested removals without deleting. |

Sources: [mise install](https://mise.jdx.dev/cli/install.html), [mise upgrade](https://mise.jdx.dev/cli/upgrade.html), [mise lockfile](https://mise.jdx.dev/dev-tools/mise-lock.html), [mise prune](https://mise.jdx.dev/cli/prune.html).

The repository's `upgrade --dry-run` currently calls `mise outdated`, which is a useful report but is less faithful than the supported `mise upgrade --dry-run` operation preview.

### Pruning

`mise prune` deletes installed versions no longer selected as the latest requested version in any config recorded under mise's tracked-config state. It can list candidates with `mise ls --prunable` and preview with `mise prune --dry-run`. Versions used only through command-line `mise exec TOOL@VERSION` or `MISE_TOOL_VERSION` environment overrides are candidates because those uses are not durable config references. [mise prune](https://mise.jdx.dev/cli/prune.html)

This is intentionally broader than "compare with the active global profile" and intentionally more conservative around previously used project configs. Consequences:

- Old project configs can keep a version alive even when the global profile no longer requests it.
- Ephemeral command-line versions can be removed.
- `mise prune --configs` cleans tracked config links that point to nonexistent configs; it should be part of maintenance when projects are deleted/moved.
- `mise prune` is appropriate for version storage, while manifest-aware `nuke` remains appropriate for removing whole tool identities that are no longer declared.

The repository's `upgrade` header advertises an optional `mise prune` step but the script does not explicitly invoke it. The report/CLI contract should not claim that separate step unless it is implemented and version-pinned. Current mise documentation also includes evolving upgrade auto-prune behavior, so a minimum mise version is needed before relying on it. [mise upgrade](https://mise.jdx.dev/cli/upgrade.html)

### Backend support and its limits

mise supports built-in languages, signed Packslip manifests, Aqua recipes, GitHub/GitLab/Forgejo releases, direct HTTP/S3 artifacts, language package managers, Conda/pkgx, and vfox/asdf plugins. A registry name maps to one or more backends; the registry entry does not guarantee a compatible artifact for every OS/architecture. mise explicitly instructs users to install and execute the result to verify support. [mise backends](https://mise.jdx.dev/dev-tools/backends/) [mise registry](https://mise.jdx.dev/registry.html)

The backend choice changes the trust and operational model:

| Backend family | Practical implication |
|---|---|
| Packslip | Preferred by mise when the publisher supplies signed manifests; strongest explicit publisher identity model. |
| Aqua | Curated recipe snapshot embedded in the mise release; mainly downloads/extracts publisher artifacts. Checksum/signature/provenance coverage varies by package metadata. |
| GitHub/GitLab | Downloads publisher release assets; platform asset matching and verification depend on release layout and available metadata. |
| Language package backend | May need Node/Python/Ruby/Go/Rust/.NET and may resolve/build transitive dependencies; top-level lock does not necessarily freeze all build inputs. |
| Conda | Installs a CLI and transitive packages into an isolated per-tool prefix; it does not manage a general `environment.yml`, and host libc/drivers still matter. |
| pkgx | Can package runtime libraries through wrappers and lock transitive pkgx packages, but the backend is experimental. |
| vfox/asdf | Executes plugin logic with user permissions and may require external commands/system libraries. asdf is legacy; new registry submissions for asdf/vfox are rejected for supply-chain reasons. |

Sources: [mise backend architecture](https://mise.jdx.dev/dev-tools/backend_architecture.html), [Aqua backend](https://mise.jdx.dev/dev-tools/backends/aqua.html), [Conda backend](https://mise.jdx.dev/dev-tools/backends/conda.html), [pkgx backend](https://mise.jdx.dev/dev-tools/backends/pkgx.html), [vfox backend](https://mise.jdx.dev/dev-tools/backends/vfox.html), [asdf backend](https://mise.jdx.dev/dev-tools/backends/asdf.html).

By default, mise uses mise/Aqua registry snapshots bundled and tested with its release. Registry corrections may therefore require a mise update. `registry_floating = true` can fetch current registries, but mise documents this as opt-in because those mappings were not tested with the installed binary. [mise registry floating behavior](https://mise.jdx.dev/registry.html#floating-registries)

The local tool observed during this research was mise `2026.5.16`, while current official documentation describes newer 2026 behavior. The repository does not emit a `min_version` requirement and its upgrade script does not call `mise self-update`. Features used as correctness guarantees should be tied to a tested minimum mise release rather than assumed from the live documentation.

## Native libraries and system integration

mise's core abstraction is a tool version installed under its data directory and exposed through executable paths/environment. It can order tool installs through `depends`, but declarations do not add an absent tool automatically. Current mise also has `system_deps` behavior for plugin-declared host prerequisites: it can prompt, install through an available system package manager, warn, or ignore. This is prerequisite orchestration, not general ownership of arbitrary host libraries. [mise dev-tool dependencies](https://mise.jdx.dev/dev-tools/#tool-dependencies) [mise `system_deps` setting](https://mise.jdx.dev/configuration/settings.html#system_deps)

Native libraries should normally remain with Homebrew on macOS and apt/dnf/pacman on Linux when any of these apply:

- A compiler or extension needs headers, `.pc` files, shared libraries, or stable prefixes.
- Multiple unrelated programs need the same host ABI/library.
- The package installs a daemon, driver, kernel/system extension, launch service, or privileged files.
- The available mise backend compiles against ambient system state without locking those inputs.
- A release binary does not include required runtime libraries for the target host.

Homebrew provides stable formula `opt` prefixes and official guidance for scoped `CPPFLAGS`, `LDFLAGS`, `PKG_CONFIG_PATH`, and `CMAKE_PREFIX_PATH`. That is exactly the integration required by packages such as Cairo/pycairo and other native extension builds. [Homebrew keg-only dependency guidance](https://docs.brew.sh/How-to-Build-Software-Outside-Homebrew-with-Homebrew-keg-only-Dependencies)

The repository's existing exceptions are therefore conceptually correct: Cairo, `pkg-config`, ImageMagick, Poppler, Ghostscript, and similar native capabilities belong to the host package manager. Formula-only CLIs such as `tree`, `wget`, or `parallel` can also remain exceptions when no tested mise backend is available. "mise first" should be a selection policy, not a schema invariant.

One concrete integration gap illustrates why binary presence is not always installation completeness: the manifest moved `git-lfs` from Homebrew to mise, but Git LFS's official setup requires `git lfs install` once per user. The Homebrew formula prints the same caveat, while an Aqua binary extraction does not imply that user Git configuration step. The repository contains no matching command. [Git LFS getting started](https://git-lfs.com/) [Official Homebrew git-lfs formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/git-lfs.rb)

## Implications of mise for nearly all developer CLIs

### Benefits

- One cross-platform, user-space location for most CLIs and runtimes.
- Exact and fuzzy version requests, multiple simultaneous versions, and project overrides.
- Better reproducibility than Homebrew for supported backends through concrete versions, checksums, platform URLs, and optional provenance.
- Real dry runs for install, upgrade, lock, uninstall, and prune.
- Less Homebrew formula graph churn on macOS and less coupling of CLI upgrades to native libraries.
- A common interface across macOS and Linux for self-contained release binaries.

### Costs and risks

- mise becomes bootstrap-critical. If it or its registry/backend is unavailable, most of the shell toolchain is unavailable on a fresh machine.
- `type: mise` hides materially different trust and reproducibility models. The current lock spans Aqua, core, GitHub, vfox, asdf, and pipx backends.
- Moving from an official Homebrew formula can replace a Homebrew-maintained source-built bottle and reviewed formula lifecycle with an upstream or third-party release binary. This is not automatically better or worse, but it is a trust-model change that should be visible.
- Release artifacts may omit man pages, completions, post-install setup, service definitions, or shell integration that a formula provided.
- Registry presence does not prove platform support. Every selected OS/architecture needs an install-and-smoke-test.
- The seven-day release-age policy is partial. It does not hold exact pins, locked selections, versions without timestamps, or most transitive build dependencies.
- mise command sandboxing does not sandbox tool installation. It only restricts child commands launched through `mise exec`/`mise run` with sandbox policy; ordinary CLI execution after shell activation runs with the user's normal privileges. [mise sandboxing](https://mise.jdx.dev/sandboxing.html)

## Implications of Homebrew Cask for macOS GUIs

### Benefits

- Declarative, inspectable application names with `brew bundle check/install/cleanup` support.
- Official cask metadata review, download integrity where checksums exist, quarantine, and Gatekeeper enforcement.
- Easy separation from versioned developer CLIs and native formulae.
- Per-cask `appdir` supports user-writable application destinations for simple app artifacts.

### Costs and risks

- No exact portable lockfile and limited control over self-updating apps.
- Vendor binaries remain the primary trust object; checksums and notarization are not source review.
- Some casks need `sudo`, run unsandboxed installers, or write outside the selected application directory.
- Managed/MDM apps can conflict with Homebrew ownership/adoption and should stay explicitly unmanaged, as the repository already does.
- Cask upgrades can affect Dock/Launchpad position and macOS permission state depending on whether Homebrew can perform an in-place replacement. [Homebrew cask upgrade FAQ](https://docs.brew.sh/FAQ#why-do-my-cask-apps-lose-their-dock-position--launchpad-position--permission-settings-when-i-run-brew-upgrade)
- `version :latest` and `auto_updates true` casks have special outdated/upgrade behavior; ordinary `brew upgrade` may skip them unless greedy behavior is selected. [Homebrew self-updating cask FAQ](https://docs.brew.sh/FAQ#how-does-brew-upgrade-handle-apps-that-update-themselves)

## Repository-specific gaps to resolve before calling the migration complete

| Priority | Gap | Why it matters |
|---|---|---|
| High | Strict mise lock mode is not enforced. | `lockfile = true` is not fail-closed; a fresh machine can resolve missing backend data instead of proving the committed lock is complete. |
| High | Linux package metadata is not executed. | `generate.py` emits Brewfiles only for macOS and `sync` runs no apt/dnf/pacman/Flatpak step. Declared native libraries, fallback CLIs, and Linux GUI mappings are metadata only. |
| High | Casks cannot be described as sandboxed. | Some casks execute unsandboxed vendor installers or `.pkg` payloads with broad/elevated writes. |
| Medium | Homebrew lock comments/config are obsolete. | Brewfile lockfiles do not exist; the current env var and ignore rule create a false reproducibility signal. |
| Medium | Missing-only Homebrew guarantee is overstated. | `--no-upgrade` still allows dependency upgrades required by `brew install`. |
| Medium | Profile lock generation is underspecified. | One mutable global config plus one committed global lock can drift between work/personal/base profile views. |
| Medium | Prune is advertised but not explicitly invoked. | Installed old versions accumulate, while users may believe `upgrade` already removes them. |
| Medium | mise version is not constrained or updated by the workflow. | Backend mappings, lock semantics, profile config behavior, and pruning are evolving; installed behavior can lag the documentation. |
| Medium | Package-specific post-install behavior is not audited. | `git-lfs` already demonstrates that a present executable may not be fully configured. |
| Low | `brew bundle check` does not use `--no-upgrade`. | The check can report outdated entries as unsatisfied even though the following install intentionally refuses upgrades, causing unnecessary work/noise. |

## Recommended migration policy

Adopt the hybrid, but make backend capability explicit:

1. **mise:** runtimes and self-contained developer CLIs with a tested macOS/Linux artifact. Prefer Packslip/Aqua/GitHub-style download backends with lock metadata. Record or validate the resolved backend, not only the shorthand.
2. **Homebrew formula/native package:** shared libraries, headers, build discovery metadata, drivers/services, and CLI exceptions where mise coverage or lifecycle behavior is weaker.
3. **Homebrew Cask:** macOS GUI applications that are not IT/MDM-owned, with the understanding that Cask is delivery and inventory, not sandboxing or exact version locking.
4. **Unmanaged:** MDM/Jamf, Mac App Store/vendor-controlled installs, and software that requires organization-specific authorization.

Operational guardrails:

- If preserving the current cross-platform/profile ambitions, keep
  `manifest.yaml` and repair its orchestration. If the goal is to remove the
  hand-rolled package manager, replace it with direct native configuration and
  accept a narrower contract.
- For a direct-config migration, use a base global mise config plus native mise
  environment overlays (`workstation`, `work`, and `personal`). mise can merge
  selected environments, although a small role selection remains necessary
  because it does not infer profile dependencies.
- Use complete per-role Brewfiles rather than additive fragments if native
  `brew bundle cleanup` will be used. Additive files are safe for installation
  but unsafe for independent cleanup.
- Use `brew bundle check --no-upgrade --verbose` for missing-only previews and retain the repository's safer cask-opt-in removal flow.
- Generate global mise locks deliberately for every supported profile/platform and install with strict locked mode on fresh-machine/CI verification.
- Use `mise upgrade --dry-run`, `mise lock --bump --dry-run`, and `mise prune --dry-run` rather than approximating those operations with status commands.
- Add a tested minimum mise version before relying on current environment/lock/prune semantics; decide separately how mise itself is upgraded.
- Smoke-test each mise CLI on every claimed OS/architecture, including shell integration, completions, man pages, config initialization, and external shared-library linkage.
- Keep native libraries explicit per OS and implement the currently missing Linux package application path.

## Migration verdict

Proceed with an aggressive configuration migration, but not an aggressive
package removal in the same step.

1. Make direct mise config/environment files and complete per-role Brewfiles
   the source of truth. Preserve the current resolved package set initially.
2. Keep a small bootstrap for Homebrew/mise installation, dotfile links,
   role selection, the two zsh plugin clones, and vendor/MDM notes. Remove the
   YAML generator, generated `out/` files, and custom package diff/removal code.
3. Fix shell ordering so Homebrew initializes before mise. Verify every intended
   mise command resolves through `mise which` before uninstalling duplicates.
4. Resolve `disk-inventory-x`, PDF/image libraries, Claude Code ownership,
   `git-filter-repo`, and the exact-versus-rolling version policy.
5. Run a fresh install on an ephemeral macOS CI runner. Casks may execute vendor
   installers, so do not use this Mac as their sandbox.
6. Activate the direct configs on this Mac without removing anything. After a
   short canary period, remove legacy formulae/version managers using an
   explicit reviewed list rather than a general-purpose `nuke` command.

This separates the reversible architectural cutover from the destructive
cleanup. Rolling back the cutover is then only a config/PATH change; installed
Homebrew and mise payloads remain available until confidence is established.

## Outcome

The migration was completed on 2026-09-18 with direct `Brewfile` and mise
configuration ownership. Existing versions seeded the new Mac-only lock before
activation, the known command collisions were verified through mise shims, and
native Homebrew/mise cleanup removed undeclared packages only after convergence
passed.

## Primary sources

### Homebrew

- [Homebrew Bundle and Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [Homebrew man page, Bundle and cleanup commands](https://docs.brew.sh/Manpage#bundle-subcommand)
- [Formula version and locking guidance](https://docs.brew.sh/Versions#locking-installed-formulae-at-specific-versions)
- [Cask Cookbook: artifact trust and sandboxing](https://docs.brew.sh/Cask-Cookbook#cask-artifact-trust-and-sandboxing)
- [Homebrew security and supply-chain model](https://docs.brew.sh/Homebrew-Security-and-Supply-Chain)
- [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)
- [Homebrew Bundle DSL source](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/dsl.rb)
- [Homebrew Bundle cask source](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/cask.rb)
- [Homebrew Bundle cleanup source](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/bundle/subcommand/cleanup.rb)
- [Apple App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)

### mise

- [Configuration](https://mise.jdx.dev/configuration.html)
- [Config environments](https://mise.jdx.dev/configuration/environments.html)
- [Settings](https://mise.jdx.dev/configuration/settings.html)
- [mise.lock](https://mise.jdx.dev/dev-tools/mise-lock.html)
- [Dev tools](https://mise.jdx.dev/dev-tools/)
- [Backends](https://mise.jdx.dev/dev-tools/backends/)
- [Backend architecture](https://mise.jdx.dev/dev-tools/backend_architecture.html)
- [Registry](https://mise.jdx.dev/registry.html)
- [Security](https://mise.jdx.dev/security.html)
- [Sandboxing](https://mise.jdx.dev/sandboxing.html)
- [Prune command](https://mise.jdx.dev/cli/prune.html)
- [Upgrade command](https://mise.jdx.dev/cli/upgrade.html)

### Package-specific validation

- [Git LFS official installation guide](https://git-lfs.com/)
- [Homebrew's official git-lfs formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/git-lfs.rb)
