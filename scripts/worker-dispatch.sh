#!/usr/bin/env bash
set -euo pipefail

# worker-dispatch.sh: Hardened universal headless worker dispatcher for spec-harness-kit
# Usage: ./scripts/worker-dispatch.sh [cheap|standard|frontier] [plan|write] <agent> <prompt> [cwd]

# 1. Anti-Recursion Guard: Prevent workers from spawning nested workers
if [[ "${SPEC_HARNESS_WORKER:-0}" == "1" ]]; then
  echo "🛑 Error: Recursive worker dispatch blocked (SPEC_HARNESS_WORKER=1 is already set)." >&2
  exit 1
fi
export SPEC_HARNESS_WORKER=1

TIER="${1:-standard}"
MODE="${2:-plan}"
AGENT="${3:-dev}"
PROMPT="${4:-}"
TARGET_CWD="${5:-$(pwd)}"
TIMEOUT_SEC="${WORKER_TIMEOUT:-180}"

if [[ -z "$PROMPT" ]]; then
  echo "Error: Prompt cannot be empty." >&2
  exit 1
fi

if [[ ! -d "$TARGET_CWD" ]]; then
  echo "Error: Target working directory does not exist: $TARGET_CWD" >&2
  exit 1
fi

# 2. Universal Scarce Frontier Guard
if [[ "$TIER" == "frontier" ]]; then
  if [[ "$MODE" != "plan" ]]; then
    echo "🛑 Scarce Frontier Guard Violation: Frontier tier must run in read-only 'plan' mode." >&2
    exit 1
  fi
  if [[ "${#PROMPT}" -gt 3500 ]]; then
    echo "🛑 Scarce Frontier Guard Violation: Prompt exceeds 3,500 chars (${#PROMPT} chars)." >&2
    echo "Pre-distill into a <= 500 word decision memo before consulting the frontier tier." >&2
    exit 1
  fi
fi

# 3. Detect available CLI provider
detect_provider() {
  if [[ -n "${SPEC_ORCHESTRATOR_PROVIDER:-}" ]]; then
    echo "$SPEC_ORCHESTRATOR_PROVIDER"
  elif command -v agy >/dev/null 2>&1; then
    echo "agy"
  elif command -v claude >/dev/null 2>&1; then
    echo "claude"
  elif command -v codex >/dev/null 2>&1; then
    echo "codex"
  elif command -v hermes >/dev/null 2>&1; then
    echo "hermes"
  else
    echo "unknown"
  fi
}

PROVIDER=$(detect_provider)

# 4. Capture pre-execution git state for non-destructive read-only tripwire
cd "$TARGET_CWD"
IN_GIT_REPO=0
PRE_STATUS=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IN_GIT_REPO=1
  PRE_STATUS=$(git status --porcelain; git diff --binary HEAD 2>/dev/null | sha256sum)
fi

now_ms() {
  date +%s%3N 2>/dev/null || echo "$(( $(date +%s) * 1000 ))"
}
START_MS=$(now_ms)

# 5. Execute provider with timeout and stripped MCP/subagent overhead
set +e
case "$PROVIDER" in
  agy)
    case "$TIER" in
      cheap)    MODEL="gemini-4-hydrogen-low"; EFFORT="low" ;;
      standard) MODEL="gemini-4-hydrogen-medium"; EFFORT="medium" ;;
      frontier) MODEL="gemini-4-hydrogen-high"; EFFORT="high" ;;
      *) echo "Unknown tier: $TIER" >&2; exit 1 ;;
    esac
    AGY_MODE=$([[ "$MODE" == "plan" ]] && echo "plan" || echo "accept-edits")
    # CRITICAL: --print="$PROMPT" must be attached and placed last so agy does not swallow flags
    timeout "${TIMEOUT_SEC}s" agy \
      --print-timeout "${TIMEOUT_SEC}s" \
      --mode "$AGY_MODE" \
      --model "$MODEL" \
      --effort "$EFFORT" \
      --agent "$AGENT" \
      --add-dir "$TARGET_CWD" \
      --print="$PROMPT"
    ;;

  claude)
    case "$TIER" in
      cheap)    MODEL="haiku"; EFFORT="low" ;;
      standard) MODEL="sonnet"; EFFORT="medium" ;;
      frontier) MODEL="opus"; EFFORT="high" ;;
      *) echo "Unknown tier: $TIER" >&2; exit 1 ;;
    esac
    CLAUDE_PERM=$([[ "$MODE" == "plan" ]] && echo "plan" || echo "acceptEdits")
    printf '%s' "$PROMPT" | timeout "${TIMEOUT_SEC}s" claude \
      --print \
      --disable-slash-commands \
      --disallowedTools "Agent,Workflow" \
      --strict-mcp-config \
      --permission-mode "$CLAUDE_PERM" \
      --model "$MODEL" \
      --effort "$EFFORT"
    ;;

  codex)
    case "$TIER" in
      cheap)    SANDBOX="read-only"; EFFORT="low" ;;
      standard) SANDBOX="workspace-write"; EFFORT="medium" ;;
      frontier) SANDBOX="read-only"; EFFORT="high" ;;
      *) echo "Unknown tier: $TIER" >&2; exit 1 ;;
    esac
    printf '%s' "$PROMPT" | timeout "${TIMEOUT_SEC}s" codex \
      --disable multi_agent \
      exec \
      --sandbox "$SANDBOX" \
      --cd "$TARGET_CWD" \
      --config "model_reasoning_effort=\"$EFFORT\"" \
      --config "mcp_servers={}" \
      -
    ;;

  hermes)
    case "$TIER" in
      cheap)    EFFORT="low" ;;
      standard) EFFORT="medium" ;;
      frontier) EFFORT="high" ;;
      *) echo "Unknown tier: $TIER" >&2; exit 1 ;;
    esac
    HERMES_EXTRA=()
    if [[ "$MODE" == "write" ]]; then
      HERMES_EXTRA+=(--yolo)
    fi
    printf '%s' "$PROMPT" | timeout "${TIMEOUT_SEC}s" hermes chat \
      --oneshot -Q \
      --ignore-rules \
      --in "$TARGET_CWD" \
      --reasoning "$EFFORT" \
      --run-budget "$TIMEOUT_SEC" \
      --source tool \
      "${HERMES_EXTRA[@]}" \
      --query-file -
    ;;

  *)
    echo "Error: No supported AI CLI detected (agy, claude, codex, hermes)." >&2
    echo "Export SPEC_ORCHESTRATOR_PROVIDER or install a supported CLI." >&2
    exit 1
    ;;
esac
WORKER_EXIT=$?
set -e

END_MS=$(now_ms)
DURATION_MS=$(( END_MS - START_MS ))

# 6. Structured JSONL Telemetry (disable with SPEC_DISABLE_TELEMETRY=1)
if [[ "${SPEC_DISABLE_TELEMETRY:-0}" != "1" ]]; then
  TELEMETRY_LOG="${SPEC_TELEMETRY_LOG:-$HOME/.cache/spec-harness-kit/telemetry.jsonl}"
  mkdir -p "$(dirname "$TELEMETRY_LOG")" 2>/dev/null || true
  TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"timestamp":"%s","provider":"%s","tier":"%s","mode":"%s","agent":"%s","prompt_chars":%d,"duration_ms":%d,"exit_code":%d}\n' \
    "$TS" "$PROVIDER" "$TIER" "$MODE" "$AGENT" "${#PROMPT}" "$DURATION_MS" "$WORKER_EXIT" >> "$TELEMETRY_LOG" 2>/dev/null || true
fi

# 7. Non-Destructive Read-Only Verification Tripwire
if [[ "$MODE" == "plan" ]] && [[ "$IN_GIT_REPO" -eq 1 ]]; then
  POST_STATUS=$(git status --porcelain; git diff --binary HEAD 2>/dev/null | sha256sum)
  if [[ "$PRE_STATUS" != "$POST_STATUS" ]]; then
    echo "⚠️ Security Alert: Read-only worker violated plan mode and modified working tree state!" >&2
    git status --short >&2
    exit 2
  fi
fi

exit "$WORKER_EXIT"
