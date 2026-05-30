#!/usr/bin/env bash
# Run bootstrap --minimal in each container, verify symlinks + zsh sourcing.
# Usage:
#   ./run-tests.sh              # all distros
#   ./run-tests.sh ubuntu       # one distro

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_TEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DISTROS=(ubuntu fedora arch)
[[ $# -gt 0 ]] && DISTROS=("$@")

# Verification commands to run inside each container after bootstrap --minimal
read -r -d '' VERIFY <<'VERIFY_EOF' || true
set -uo pipefail
echo
echo "--- post-bootstrap state ---"

# 1. Symlinks landed
for f in ~/.zshrc ~/.tmux.conf ~/.gitconfig ~/.config/zsh/.zshrc; do
  if [[ -L "$f" ]]; then
    echo "  ✓ symlink: $f → $(readlink "$f")"
  else
    echo "  ✗ MISSING symlink: $f"
    exit 1
  fi
done

# 2. zsh plugins cloned
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  if [[ -d "$HOME/.config/zsh/plugins/$p/.git" ]]; then
    echo "  ✓ plugin cloned: $p"
  else
    echo "  ✗ plugin missing: $p"
    exit 1
  fi
done

# 3. Sourcing works without errors
zsh -i -c 'echo "  ✓ interactive zsh started"; echo "  ENV_DIR=$ENV_DIR"; echo "  PATH=$PATH" | head -c 80; echo' || {
  echo "  ✗ zsh interactive failed"
  exit 1
}

echo
echo "RESULT: PASS"
VERIFY_EOF

PASS=0
FAIL=0
FAILED_DISTROS=()

for distro in "${DISTROS[@]}"; do
  echo
  echo "═════════════════════════════════════════"
  echo "  $distro"
  echo "═════════════════════════════════════════"

  IMAGE="env-test-$distro:latest"

  # Build (cached after first run)
  echo "→ building $IMAGE"
  docker build -q -t "$IMAGE" -f "$SCRIPT_DIR/Dockerfile.$distro" "$SCRIPT_DIR" || {
    echo "  ✗ docker build failed for $distro"
    FAIL=$((FAIL+1))
    FAILED_DISTROS+=("$distro (build)")
    continue
  }

  # Run bootstrap --minimal then verify
  echo "→ running: bootstrap --minimal + verification"
  docker run --rm \
    -v "$ENV_TEST_DIR":/env:ro \
    "$IMAGE" \
    /bin/zsh -c "
      set -uo pipefail
      cp -r /env \$HOME/environment
      cd \$HOME/environment
      ./bootstrap --minimal
      $VERIFY
    "
  rc=$?

  if [[ $rc -eq 0 ]]; then
    echo
    echo "✓ $distro PASSED"
    PASS=$((PASS+1))
  else
    echo
    echo "✗ $distro FAILED (rc=$rc)"
    FAIL=$((FAIL+1))
    FAILED_DISTROS+=("$distro (verify rc=$rc)")
  fi
done

echo
echo "═════════════════════════════════════════"
echo "  Summary: $PASS passed, $FAIL failed"
echo "═════════════════════════════════════════"
if [[ $FAIL -gt 0 ]]; then
  printf '  failed: %s\n' "${FAILED_DISTROS[@]}"
  exit 1
fi
