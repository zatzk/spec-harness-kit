#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: scans edited code files for mechanical rule violations
# (hardcoded secret fallbacks, TypeScript 'any', ::ng-deep, leftover [DEBUG-*] logs)
# and records a workspace dirty marker for stop-verify-gate.sh.

TARGET_FILE="${1:-}"
if [[ -z "$TARGET_FILE" ]]; then
  INPUT="$(cat || true)"
  if [[ -n "$INPUT" ]]; then
    if command -v jq >/dev/null 2>&1; then
      TARGET_FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
    else
      TARGET_FILE="$(python3 -c "import json,sys; d=json.load(sys.stdin); ti=d.get('tool_input') or {}; print(ti.get('file_path') or ti.get('path') or '')" <<< "$INPUT" 2>/dev/null || true)"
    fi
  fi
fi

if [[ -z "$TARGET_FILE" || ! -f "$TARGET_FILE" ]]; then
  exit 0
fi

EXT="${TARGET_FILE##*.}"
case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs|py|go|html|scss|css) ;;
  *) exit 0 ;;
esac

VIOLATIONS=""

# 1. Hardcoded env secret/config fallback (e.g. process.env.JWT_SECRET || 'dev')
MATCHES="$(grep -nE "process\.env\.[A-Z0-9_]+[[:space:]]*(\|\||\?\?)[[:space:]]*['\"][^'\"]+['\"]" "$TARGET_FILE" || true)"
if [[ -n "$MATCHES" ]]; then
  VIOLATIONS+=$'\n'"[Regra Zero: Hardcoded env fallback in $TARGET_FILE]"$'\n'"$MATCHES"
fi

# 2. TypeScript explicit 'any'
if [[ "$EXT" == "ts" || "$EXT" == "tsx" ]]; then
  MATCHES="$(grep -nE "(:\s*any\b|\bas\s+any\b)" "$TARGET_FILE" || true)"
  if [[ -n "$MATCHES" ]]; then
    VIOLATIONS+=$'\n'"[Strict Typing: forbidden 'any' in $TARGET_FILE]"$'\n'"$MATCHES"
  fi
fi

# 3. Angular ::ng-deep
if [[ "$EXT" == "scss" || "$EXT" == "css" || "$EXT" == "ts" || "$EXT" == "html" ]]; then
  MATCHES="$(grep -nE "::ng-deep" "$TARGET_FILE" || true)"
  if [[ -n "$MATCHES" ]]; then
    VIOLATIONS+=$'\n'"[Angular Standard: forbidden ::ng-deep in $TARGET_FILE]"$'\n'"$MATCHES"
  fi
fi

# 4. Leftover [DEBUG-*] instrumentation markers
MATCHES="$(grep -nE "\[DEBUG-[a-zA-Z0-9_-]+\]" "$TARGET_FILE" || true)"
if [[ -n "$MATCHES" ]]; then
  VIOLATIONS+=$'\n'"[Cleanup: leftover debug tag in $TARGET_FILE]"$'\n'"$MATCHES"
fi

# Mark workspace dirty so stop-verify-gate.sh knows checks must run
WORKSPACE_HASH="$(printf '%s' "$PWD" | sha256sum | cut -c1-12)"
DIRTY_MARKER="${TMPDIR:-/tmp}/spec-harness-dirty-${WORKSPACE_HASH}"
touch "$DIRTY_MARKER"

if [[ -n "$VIOLATIONS" ]]; then
  echo "BLOCKED by post-edit-guard:$VIOLATIONS" >&2
  exit 2
fi

exit 0
