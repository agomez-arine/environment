#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6.0"]
# ///
"""
Generate per-profile mise + Brewfile + uninstall.sh + cleanup.sh from
manifest.yaml + cleanup.yaml.

Usage:
    ./generate.py                                     # all profiles, target=mac
    ./generate.py --target linux                      # linux outputs
    ./generate.py --profiles base,work                # only emit these profile slices
    ./generate.py --check                             # validate only, no output
    ./generate.py --out <dir>                         # output dir (default: out)

Schema features (Wave 1):
    - profiles: unified definition + membership (description, marker, os, requires, packages)
    - registry: keyed by package name, polymorphic on `type:`
                (mise | brew | cask | bootstrap | git_clone | unmanaged)
    - mise tools always have `versions:` (a list, first = default)
    - drop / cleanup live in cleanup.yaml as flat lists with `category:` field
    - schema_version: "1.0"
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter
from pathlib import Path
from typing import Any

import yaml


VALID_OS = {"mac", "linux"}
VALID_TYPES = {"mise", "brew", "cask", "bootstrap", "git_clone", "unmanaged"}
VALID_ACTIONS = {"nuke", "review", "command"}
DEFAULT_OS = ["mac", "linux"]
DEFAULT_PROFILES = ["base"]
SUPPORTED_SCHEMA_VERSION = "1.0"


def load(path: Path) -> dict[str, Any]:
    with path.open() as f:
        return yaml.safe_load(f)


def applies_to_os(item: dict, target_os: str) -> bool:
    item_os = item.get("os", DEFAULT_OS)
    if isinstance(item_os, str):
        item_os = [item_os]
    return target_os in item_os


def applies_to_profiles(item: dict, active_profiles: set[str]) -> bool:
    item_profiles = item.get("profiles", DEFAULT_PROFILES)
    if isinstance(item_profiles, str):
        item_profiles = [item_profiles]
    return bool(active_profiles & set(item_profiles))


def resolve_requires(profile_name: str, profiles: dict[str, dict], seen: set[str] | None = None) -> set[str]:
    """Walk the requires chain transitively. Returns the closure including the
    starting profile. Catches cycles."""
    if seen is None:
        seen = set()
    if profile_name in seen:
        raise ValueError(f"profile dependency cycle detected at {profile_name!r}")
    if profile_name not in profiles:
        raise ValueError(f"unknown profile {profile_name!r} referenced in requires chain")
    seen = seen | {profile_name}
    closure = {profile_name}
    for req in profiles[profile_name].get("requires", []):
        closure |= resolve_requires(req, profiles, seen)
    return closure


def validate_manifest(manifest: dict[str, Any]) -> list[str]:
    errors = []

    sv = manifest.get("schema_version")
    if sv != SUPPORTED_SCHEMA_VERSION:
        errors.append(f"schema_version: expected {SUPPORTED_SCHEMA_VERSION!r}, got {sv!r}")

    profiles = manifest.get("profiles", {}) or {}
    registry = manifest.get("registry", {}) or {}

    # Validate profile structure
    for prof_name, prof_data in profiles.items():
        if not isinstance(prof_data, dict):
            errors.append(f"profile {prof_name!r}: must be a mapping")
            continue
        for required_field in ("description", "os", "requires", "packages"):
            if required_field not in prof_data:
                errors.append(f"profile {prof_name!r}: missing field {required_field!r}")

        # OS values
        prof_os = prof_data.get("os", DEFAULT_OS)
        if isinstance(prof_os, str):
            prof_os = [prof_os]
        bad = set(prof_os) - VALID_OS
        if bad:
            errors.append(f"profile {prof_name!r}: unknown os {bad}")

        # Requires references
        for req in prof_data.get("requires", []):
            if req not in profiles:
                errors.append(f"profile {prof_name!r}: requires unknown profile {req!r}")

    # Cycle detection (transitive resolve)
    for prof_name in profiles:
        try:
            resolve_requires(prof_name, profiles)
        except ValueError as e:
            errors.append(str(e))

    # Validate registry entries
    for pkg_name, pkg_data in registry.items():
        if not isinstance(pkg_data, dict):
            errors.append(f"registry {pkg_name!r}: must be a mapping")
            continue
        ptype = pkg_data.get("type")
        if ptype not in VALID_TYPES:
            errors.append(f"registry {pkg_name!r}: invalid type {ptype!r}, must be one of {sorted(VALID_TYPES)}")
            continue

        # OS values
        pkg_os = pkg_data.get("os", DEFAULT_OS)
        if isinstance(pkg_os, str):
            pkg_os = [pkg_os]
        bad = set(pkg_os) - VALID_OS
        if bad:
            errors.append(f"registry {pkg_name!r}: unknown os {bad}")

        # Type-specific required fields
        if ptype == "mise":
            if "versions" not in pkg_data:
                errors.append(f"registry {pkg_name!r}: mise type requires `versions:` (list)")
            elif not isinstance(pkg_data["versions"], list) or not pkg_data["versions"]:
                errors.append(f"registry {pkg_name!r}: `versions:` must be a non-empty list")
        elif ptype == "bootstrap":
            if "via" not in pkg_data:
                errors.append(f"registry {pkg_name!r}: bootstrap type requires `via:`")
        elif ptype == "git_clone":
            for f in ("repo", "clone_to"):
                if f not in pkg_data:
                    errors.append(f"registry {pkg_name!r}: git_clone type requires {f!r}")

    # Validate every profile-listed package exists in registry
    for prof_name, prof_data in profiles.items():
        for pkg in prof_data.get("packages", []) or []:
            pkg_name = pkg if isinstance(pkg, str) else pkg.get("name")
            if pkg_name not in registry:
                errors.append(f"profile {prof_name!r}: references unknown package {pkg_name!r}")

    return errors


def validate_cleanup(cleanup_doc: dict[str, Any]) -> list[str]:
    errors = []
    sv = cleanup_doc.get("schema_version")
    if sv != SUPPORTED_SCHEMA_VERSION:
        errors.append(f"cleanup.yaml schema_version: expected {SUPPORTED_SCHEMA_VERSION!r}, got {sv!r}")

    # drop entries
    for i, entry in enumerate(cleanup_doc.get("drop", []) or []):
        if not isinstance(entry, dict):
            errors.append(f"drop[{i}]: must be a mapping")
            continue
        for f in ("name", "category", "reason"):
            if f not in entry:
                errors.append(f"drop[{i}] {entry.get('name', '?')}: missing {f!r}")

    # cleanup entries
    for i, entry in enumerate(cleanup_doc.get("cleanup", []) or []):
        if not isinstance(entry, dict):
            errors.append(f"cleanup[{i}]: must be a mapping")
            continue
        action = entry.get("action")
        if action not in VALID_ACTIONS:
            errors.append(f"cleanup[{i}]: invalid action {action!r}")
            continue
        if "category" not in entry:
            errors.append(f"cleanup[{i}]: missing category")
        if action in ("nuke", "review") and "path" not in entry:
            errors.append(f"cleanup[{i}]: action={action!r} requires `path:`")
        if action == "command" and "cmd" not in entry:
            errors.append(f"cleanup[{i}]: action='command' requires `cmd:`")

        # OS values
        item_os = entry.get("os", DEFAULT_OS)
        if isinstance(item_os, str):
            item_os = [item_os]
        bad = set(item_os) - VALID_OS
        if bad:
            errors.append(f"cleanup[{i}]: unknown os {bad}")

    return errors


def collect_profile_packages(manifest: dict, profile_name: str, target_os: str) -> list[dict]:
    """Return the registry entries (with their `name` injected) for packages
    listed in the given profile, filtered by OS."""
    profiles = manifest["profiles"]
    registry = manifest["registry"]
    if profile_name not in profiles:
        return []
    out = []
    for pkg in profiles[profile_name].get("packages", []) or []:
        pkg_name = pkg if isinstance(pkg, str) else pkg["name"]
        entry = registry.get(pkg_name)
        if entry is None:
            continue
        if not applies_to_os(entry, target_os):
            continue
        out.append({"name": pkg_name, **entry})
    return out


# ──────────────────────────────────────────────────────────────────────────
# Emitters
# ──────────────────────────────────────────────────────────────────────────

def emit_mise_toml(manifest: dict, profile: str, target_os: str) -> str:
    pkgs = [p for p in collect_profile_packages(manifest, profile, target_os)
            if p["type"] == "mise"]
    lines = [
        "# Generated from manifest.yaml — do not edit by hand.",
        f"# Profile: {profile}, target OS: {target_os}",
        "",
        "[tools]",
    ]
    for pkg in pkgs:
        name = pkg["name"]
        key = name.split("/")[-1]
        versions = pkg["versions"]
        if len(versions) == 1:
            version_repr = f'"{versions[0]}"'
        else:
            version_repr = "[" + ", ".join(f'"{v}"' for v in versions) + "]"
        lines.append(f"{key} = {version_repr}")
    if pkgs:
        lines.extend([
            "",
            "[settings]",
            "experimental = true",
            "auto_install = true",
            "lockfile = true",
            'minimum_release_age = "7d"   # supply-chain mitigation: refuse versions released <7 days ago',
        ])
    return "\n".join(lines) + "\n"


def emit_brewfile(manifest: dict, profile: str) -> str:
    """brew is mac-only by design."""
    pkgs = [p for p in collect_profile_packages(manifest, profile, "mac")
            if p["type"] in ("brew", "cask")]
    lines = [
        "# Generated from manifest.yaml — do not edit by hand.",
        f"# Profile: {profile}, target: brew on macOS",
        "",
    ]
    if not pkgs:
        return "\n".join(lines) + "\n"

    # Group: formulae first, then casks
    formulae = [p for p in pkgs if p["type"] == "brew"]
    casks = [p for p in pkgs if p["type"] == "cask"]
    # IT/Jamf-managed casks can't be installed by `brew bundle` (sudo is gated
    # behind an IT authorization code), so exclude them from the Brewfile but
    # record them as comments for visibility.
    it_managed = [p for p in casks if p.get("it_managed")]
    casks = [p for p in casks if not p.get("it_managed")]
    if formulae:
        lines.append("# ─── formulae ───")
        for pkg in formulae:
            tap = pkg.get("tap")
            if tap:
                lines.append(f'tap "{tap}"')
            quoted = f'"{tap}/{pkg["name"]}"' if tap else f'"{pkg["name"]}"'
            lines.append(f"brew {quoted}")
        lines.append("")
    if casks:
        lines.append("# ─── casks ───")
        for pkg in casks:
            # Casks marked `appdir:` install into a user-writable dir (e.g.
            # ~/Applications) to bypass PrivilegeManagement/sudo gates on the
            # work mac. Per-cask so it doesn't affect other casks.
            appdir = pkg.get("appdir")
            if appdir:
                lines.append(f'cask "{pkg["name"]}", args: {{ appdir: "{appdir}" }}')
            else:
                lines.append(f'cask "{pkg["name"]}"')
    if it_managed:
        lines.append("")
        lines.append("# ─── IT/Jamf-managed (NOT installed by brew) ───")
        for pkg in it_managed:
            lines.append(f'# cask "{pkg["name"]}"  # it_managed: installed by IT/Jamf')
    return "\n".join(lines) + "\n"


def emit_uninstall_sh(cleanup_doc: dict) -> str:
    drops = cleanup_doc.get("drop", []) or []
    lines = [
        "#!/usr/bin/env bash",
        "# Generated from cleanup.yaml — do not edit by hand.",
        "# One-shot uninstall (per machine, during migration).",
        "set -uo pipefail",
        "",
        "echo '=== Uninstall (legacy / superseded packages) ==='",
        'brew bundle dump --describe --file="$HOME/.brew-backup-$(date +%Y%m%d-%H%M%S).txt" 2>/dev/null || true',
        "",
    ]
    # Group by category for readability
    by_cat: dict[str, list[dict]] = {}
    for d in drops:
        by_cat.setdefault(d["category"], []).append(d)
    for cat, items in by_cat.items():
        lines.append(f"# ─── {cat} ───")
        for d in items:
            comment = f"  # {d['reason']}" if d.get("reason") else ""
            lines.append(f'brew uninstall --ignore-dependencies "{d["name"]}" 2>/dev/null || true{comment}')
        lines.append("")
    lines.extend([
        "echo 'Running brew autoremove...'",
        "brew autoremove",
    ])
    return "\n".join(lines) + "\n"


def _shell_path(path: str) -> str:
    if path.startswith("~/"):
        return "$HOME/" + path[2:]
    if path == "~":
        return "$HOME"
    return path


def _has_glob(path: str) -> bool:
    return any(c in path for c in "*?[")


def emit_cleanup_sh(cleanup_doc: dict, profiles: list[str], target_os: str) -> str:
    items = cleanup_doc.get("cleanup", []) or []
    profile_set = set(profiles)
    lines = [
        "#!/usr/bin/env bash",
        "# Generated from cleanup.yaml — do not edit by hand.",
        "# Filesystem cleanup (paths/commands). Idempotent.",
        f"# Profiles: {','.join(profiles)}, target OS: {target_os}",
        "set -uo pipefail",
        "",
        "echo '=== Cleanup script ==='",
        "echo",
        'BACKUP_LOG="$HOME/.cleanup-log-$(date +%Y%m%d-%H%M%S).txt"',
        'echo "logging to $BACKUP_LOG"',
        "",
    ]

    # Filter by profile + OS, then group by category
    relevant = []
    for entry in items:
        if not applies_to_profiles(entry, profile_set):
            continue
        if not applies_to_os(entry, target_os):
            continue
        relevant.append(entry)

    by_cat: dict[str, list[dict]] = {}
    for entry in relevant:
        by_cat.setdefault(entry["category"], []).append(entry)

    for cat, group in by_cat.items():
        lines.append(f"# ───── {cat} ─────")
        lines.append(f'echo "=== {cat} ==="')
        for entry in group:
            action = entry["action"]
            reclaim = entry.get("reclaim", "")
            comment = f"  # {reclaim}" if reclaim else ""
            if action == "command":
                cmd = entry["cmd"]
                lines.append(f'echo "  [run] {cmd}"{comment}')
                lines.append(f"{cmd} || true")
            elif action in ("nuke", "review"):
                raw = entry["path"]
                shp = _shell_path(raw)
                is_glob = _has_glob(shp)
                if action == "nuke":
                    lines.append(f'echo "  [nuke] {raw}" >> "$BACKUP_LOG"')
                    if is_glob:
                        lines.append(f"rm -rf {shp} 2>/dev/null || true{comment}")
                    else:
                        lines.append(f'rm -rf "{shp}" 2>/dev/null || true{comment}')
                else:  # review
                    notes = entry.get("notes", "")
                    suffix = f" — {notes}" if notes else ""
                    lines.append(f'echo "  [review] {raw}{suffix}"{comment}')
                    if is_glob:
                        lines.append(f"ls -lhd {shp} 2>/dev/null || true")
                    else:
                        lines.append(f'ls -lhd "{shp}" 2>/dev/null || true')
        lines.append("")
    lines.append('echo "Done. Review log: $BACKUP_LOG"')
    return "\n".join(lines) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="manifest.yaml", type=Path)
    ap.add_argument("--cleanup-file", default="cleanup.yaml", type=Path)
    ap.add_argument("--out", default="out", type=Path)
    ap.add_argument("--target", default="mac", choices=["mac", "linux"])
    ap.add_argument("--profiles", default=None,
                    help="comma-separated profiles to emit (default: all in manifest)")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    if not args.manifest.exists():
        print(f"error: {args.manifest} not found", file=sys.stderr)
        sys.exit(1)

    manifest = load(args.manifest)
    cleanup_doc = load(args.cleanup_file) if args.cleanup_file.exists() else {"drop": [], "cleanup": []}

    errors = validate_manifest(manifest) + validate_cleanup(cleanup_doc)
    if errors:
        print("Validation errors:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)
    print("validation: ok")

    if args.check:
        return

    if args.profiles:
        profiles = [p.strip() for p in args.profiles.split(",") if p.strip()]
    else:
        profiles = list(manifest["profiles"].keys())

    args.out.mkdir(parents=True, exist_ok=True)
    print(f"target os: {args.target}")
    print(f"emitting profiles: {profiles}")
    print()

    for profile in profiles:
        if profile not in manifest["profiles"]:
            print(f"  WARN: unknown profile {profile!r}, skipping")
            continue
        # mise per profile
        mise_path = args.out / f"mise.config.{profile}.toml"
        mise_path.write_text(emit_mise_toml(manifest, profile, args.target))
        # brewfile per profile (mac only)
        if args.target == "mac":
            brew_path = args.out / f"Brewfile.{profile}"
            brew_path.write_text(emit_brewfile(manifest, profile))
        # counts
        pkgs = collect_profile_packages(manifest, profile, args.target)
        n_mise = sum(1 for p in pkgs if p["type"] == "mise")
        n_brew = sum(1 for p in pkgs if p["type"] in ("brew", "cask"))
        n_other = len(pkgs) - n_mise - n_brew
        print(f"  {profile:14s} mise={n_mise:3d} brew={n_brew:3d} other={n_other:3d}")

    # uninstall.sh + cleanup.sh (single each, profile-aware for cleanup)
    if args.target == "mac":
        u_path = args.out / "uninstall.sh"
        u_path.write_text(emit_uninstall_sh(cleanup_doc))
        u_path.chmod(0o755)
        c_path = args.out / "cleanup.sh"
        c_path.write_text(emit_cleanup_sh(cleanup_doc, profiles, args.target))
        c_path.chmod(0o755)

    print()
    print(f"wrote {len(list(args.out.glob('*')))} files to {args.out}/")


if __name__ == "__main__":
    main()
