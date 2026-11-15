#!/usr/bin/env bash
set -euo pipefail

# Stop hook: blocks agent completion if code files were edited since last passing check.
# Active when SPEC_VERIFY_CMD is set OR SPEC_ENFORCE_STOP_GATE=1.

WORKSPACE_HASH="$(printf '%s' "$PWD" | sha256sum | cut -c1-12)"
DIRTY_MARKER="${TMPDIR:-/tmp}/spec-harness-dirty-${WORKSPACE_HASH}"

if [[ ! -f "$DIRTY_MARKER" ]]; then
  exit 0
fi

VERIFY_CMD="${SPEC_VERIFY_CMD:-}"
if [[ -z "$VERIFY_CMD" ]]; then
  if [[ "${SPEC_ENFORCE_STOP_GATE:-0}" != "1" ]]; then
    exit 0
  fi
  if [[ -f "package.json" ]]; then
    VERIFY_CMD="npm test --if-present"
  elif [[ -f "pyproject.toml" || -f "pytest.ini" || -d "tests" ]]; then
    if command -v pytest >/dev/null 2>&1; then
      VERIFY_CMD="pytest"
    else
      VERIFY_CMD="python3 -m unittest discover -s tests -p 'test_*.py'"
    fi
  elif [[ -f "go.mod" ]]; then
    VERIFY_CMD="go test ./..."
  else
    exit 0
  fi
fi

set +e
OUTPUT="$(bash -c "$VERIFY_CMD" 2>&1)"
STATUS=$?
set -e

if [[ $STATUS -ne 0 ]]; then
  echo "BLOCKED by stop-verify-gate: verification command failed ('$VERIFY_CMD', exit $STATUS):" >&2
  echo "$OUTPUT" | tail -n 40 >&2
  exit 2
fi

rm -f "$DIRTY_MARKER"
exit 0
