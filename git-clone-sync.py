#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6.0"]
# ///
"""
git-clone-sync — clone, pin, and run install: directives for every git_clone
entry in manifest.yaml that's active for the given profiles.

Modes:
    ./git-clone-sync                    enforce pinned commits (idempotent)
    ./git-clone-sync --update-clones    fetch latest, write new SHAs back to
                                        manifest.yaml, then enforce

Both modes also run `install:` directives (symlink/copy files out of the clone).
Used by bootstrap (first-time install) and sync (re-runs).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml


def expand(path: str) -> Path:
    return Path(os.path.expanduser(path))


def run(cmd: list[str], cwd: Path | None = None, capture: bool = True) -> tuple[int, str, str]:
    proc = subprocess.run(
        cmd,
        cwd=cwd,
        capture_output=capture,
        text=True,
        check=False,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def get_active_profiles(env_dir: Path) -> list[str]:
    """Replicates the marker logic in `sync` (bash). Keep in sync."""
    marker_dir = expand("~/.config/environment")
    active = ["base"]
    if (marker_dir / "profile-workstation").exists():
        active.append("workstation")
    if (marker_dir / "profile-work").exists():
        active += ["workstation", "work"]
    if (marker_dir / "profile-personal").exists():
        active += ["workstation", "personal"]
    if (marker_dir / "profile-server").exists():
        active.append("server")
    # de-dupe preserving order
    seen, out = set(), []
    for p in active:
        if p not in seen:
            seen.add(p)
            out.append(p)
    return out


def detect_os() -> str:
    import platform
    s = platform.system()
    if s == "Darwin":
        return "mac"
    if s == "Linux":
        return "linux"
    print(f"unsupported OS: {s}", file=sys.stderr)
    sys.exit(1)


def load_git_clones(env_dir: Path, profiles: list[str], target_os: str) -> list[dict]:
    """Shell out to generate.py --list-git-clones for the source-of-truth list."""
    rc, stdout, stderr = run(
        ["./generate.py", "--target", target_os, "--profiles", ",".join(profiles), "--list-git-clones"],
        cwd=env_dir,
    )
    if rc != 0:
        print(f"generate.py failed:\n{stderr}", file=sys.stderr)
        sys.exit(1)
    # generate.py prints "validation: ok" first, then the JSON. Strip prefix.
    json_start = stdout.find("[")
    if json_start < 0:
        print(f"could not find JSON in generate.py output:\n{stdout}", file=sys.stderr)
        sys.exit(1)
    return json.loads(stdout[json_start:])


def ensure_clone(entry: dict) -> tuple[bool, str]:
    """Clone if missing, then `git fetch --tags && git checkout <commit>`.
    Returns (changed, message)."""
    repo = entry["repo"]
    commit = entry["commit"]
    dst = expand(entry["clone_to"])
    name = entry["name"]

    if not (dst / ".git").is_dir():
        dst.parent.mkdir(parents=True, exist_ok=True)
        rc, _, err = run(["git", "clone", repo, str(dst)])
        if rc != 0:
            return False, f"  ✗ {name}: clone failed: {err}"
        # fall through to pin

    # Currently checked-out hash
    rc, current, _ = run(["git", "rev-parse", "HEAD"], cwd=dst)
    if rc == 0 and current == commit:
        return False, f"  · {name}: already at {commit[:7]}"

    # Need to fetch + checkout. Use --tags so tag-based pins still work later.
    rc, _, err = run(["git", "fetch", "--tags", "origin"], cwd=dst)
    if rc != 0:
        return False, f"  ✗ {name}: fetch failed: {err}"
    rc, _, err = run(["git", "checkout", "--detach", commit], cwd=dst)
    if rc != 0:
        return False, f"  ✗ {name}: checkout {commit[:7]} failed: {err}"
    return True, f"  ✓ {name}: {(current or 'fresh')[:7]} → {commit[:7]}"


def run_install_directives(entry: dict) -> list[str]:
    """Symlink/copy files out of the clone per the `install:` field."""
    msgs = []
    install = entry.get("install") or []
    if not install:
        return msgs
    clone_root = expand(entry["clone_to"])
    name = entry["name"]
    for item in install:
        src = clone_root / item["from"]
        dst = expand(item["to"])
        raw_mode = item.get("mode", 0o755)
        if isinstance(raw_mode, int):
            # YAML may parse 0755 as decimal 493; if user wrote "0755" as a
            # string we want octal. Heuristic: ints in this range came from
            # `0755` written without quotes — treat as already octal.
            mode = raw_mode if raw_mode <= 0o777 else 0o755
        else:
            mode = int(str(raw_mode), 8)
        link = item.get("link", True)

        if not src.exists():
            msgs.append(f"  ✗ {name}: install src missing: {src}")
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)

        # Decide if we need to act
        if link:
            if dst.is_symlink() and dst.resolve() == src.resolve():
                msgs.append(f"  · {name}: link OK ({dst} → {src})")
                continue
            if dst.exists() or dst.is_symlink():
                dst.unlink()
            dst.symlink_to(src)
            msgs.append(f"  ✓ {name}: linked {dst} → {src}")
        else:
            # Copy if missing or different
            if dst.exists() and dst.is_file() and dst.read_bytes() == src.read_bytes():
                msgs.append(f"  · {name}: copy OK ({dst})")
                continue
            shutil.copy2(src, dst)
            os.chmod(dst, mode)
            msgs.append(f"  ✓ {name}: copied {src} → {dst}")
    return msgs


def update_manifest_commit(manifest_path: Path, pkg_name: str, new_commit: str) -> None:
    """In-place edit of manifest.yaml: replace the `commit:` value under the
    given top-level registry entry. Preserves comments & formatting (regex-based,
    not a YAML round-trip, because PyYAML mangles that)."""
    text = manifest_path.read_text()
    # Match: pkg_name: at indent of 2 spaces (under registry:), then within its
    # block, find `    commit: <hex>` on a line by itself.
    pattern = re.compile(
        r"(^  " + re.escape(pkg_name) + r":\n(?:[ \t].*\n)*?    commit:\s+)([0-9a-f]{7,40})(.*$)",
        re.MULTILINE,
    )
    new_text, n = pattern.subn(rf"\g<1>{new_commit}\g<3>", text, count=1)
    if n != 1:
        raise RuntimeError(f"could not find commit: line for {pkg_name}")
    manifest_path.write_text(new_text)


def update_clones(env_dir: Path, entries: list[dict]) -> list[tuple[str, str, str]]:
    """For each entry, fetch latest origin/HEAD and rewrite manifest.yaml's
    commit: field. Returns list of (name, old, new) for things that changed."""
    bumps = []
    manifest_path = env_dir / "manifest.yaml"
    for entry in entries:
        name = entry["name"]
        dst = expand(entry["clone_to"])
        old = entry["commit"]
        if not (dst / ".git").is_dir():
            print(f"  · {name}: not yet cloned — will use HEAD from upstream")
            rc, latest, err = run(["git", "ls-remote", entry["repo"], "HEAD"])
            if rc != 0:
                print(f"  ✗ {name}: ls-remote failed: {err}", file=sys.stderr)
                continue
            new = latest.split()[0]
        else:
            rc, _, err = run(["git", "fetch", "origin"], cwd=dst)
            if rc != 0:
                print(f"  ✗ {name}: fetch failed: {err}", file=sys.stderr)
                continue
            rc, new, err = run(["git", "rev-parse", "origin/HEAD"], cwd=dst)
            if rc != 0:
                # Fall back to default branch resolution
                rc, sym, _ = run(["git", "symbolic-ref", "refs/remotes/origin/HEAD"], cwd=dst)
                if rc == 0:
                    branch = sym.replace("refs/remotes/origin/", "")
                    rc, new, err = run(["git", "rev-parse", f"origin/{branch}"], cwd=dst)
                if rc != 0:
                    print(f"  ✗ {name}: rev-parse origin/HEAD failed: {err}", file=sys.stderr)
                    continue
        if new != old:
            update_manifest_commit(manifest_path, name, new)
            bumps.append((name, old, new))
            print(f"  ↑ {name}: {old[:7]} → {new[:7]} (manifest updated)")
        else:
            print(f"  · {name}: already latest ({old[:7]})")
    return bumps


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--update-clones", action="store_true",
                    help="fetch latest origin/HEAD for every git_clone, write new SHAs to manifest.yaml")
    ap.add_argument("--profiles", default=None,
                    help="comma-separated; default: read marker files like sync does")
    ap.add_argument("--target", default=None, choices=["mac", "linux"],
                    help="default: auto-detect")
    args = ap.parse_args()

    env_dir = Path(__file__).resolve().parent
    target_os = args.target or detect_os()
    profiles = args.profiles.split(",") if args.profiles else get_active_profiles(env_dir)

    print(f"═══ git-clone-sync ═══")
    print(f"profiles: {','.join(profiles)}")
    print(f"os:       {target_os}")
    print()

    entries = load_git_clones(env_dir, profiles, target_os)
    if not entries:
        print("(no git_clone entries active)")
        return

    if args.update_clones:
        # Need clones to exist before we can `git fetch` in them. Enforce first.
        print("→ ensuring clones exist before update")
        for entry in entries:
            _, msg = ensure_clone(entry)
            print(msg)
        print()
        print("→ checking for upstream updates")
        bumps = update_clones(env_dir, entries)
        print()
        if bumps:
            print(f"updated {len(bumps)} entries in manifest.yaml. Re-running enforce…")
            print()
            # Re-load entries to pick up new commits
            entries = load_git_clones(env_dir, profiles, target_os)
        else:
            print("nothing to update.")
            return

    print("→ enforcing pinned commits")
    any_changed = False
    for entry in entries:
        changed, msg = ensure_clone(entry)
        any_changed = any_changed or changed
        print(msg)

    print()
    print("→ running install: directives")
    for entry in entries:
        for msg in run_install_directives(entry):
            print(msg)

    print()
    print("✓ git-clone-sync complete")


if __name__ == "__main__":
    main()
