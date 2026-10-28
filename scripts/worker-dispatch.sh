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

# 5. Execute provider with timeout and stripped MCP/subagent overhead
case "$PROVIDER" in
  agy)
    case "$TIER" in
      cheap)    MODEL="gemini-3.8-flash-low"; EFFORT="low" ;;
      standard) MODEL="gemini-3.8-flash-high"; EFFORT="medium" ;;
      frontier) MODEL="gemini-4-argon-low"; EFFORT="low" ;;
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

  *)
    echo "Error: No supported AI CLI detected (agy, claude, codex)." >&2
    echo "Export SPEC_ORCHESTRATOR_PROVIDER or install a supported CLI." >&2
    exit 1
    ;;
esac

# 6. Non-Destructive Read-Only Verification Tripwire
if [[ "$MODE" == "plan" ]] && [[ "$IN_GIT_REPO" -eq 1 ]]; then
  POST_STATUS=$(git status --porcelain; git diff --binary HEAD 2>/dev/null | sha256sum)
  if [[ "$PRE_STATUS" != "$POST_STATUS" ]]; then
    echo "⚠️ Security Alert: Read-only worker violated plan mode and modified working tree state!" >&2
    git status --short >&2
    exit 2
  fi
fi
