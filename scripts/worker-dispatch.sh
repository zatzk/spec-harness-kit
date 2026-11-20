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

# 5. Configure OS-level sandbox wrapper (ai-jail v3.0.1+ contract)
SPEC_SANDBOX="${SPEC_SANDBOX:-auto}"
case "$SPEC_SANDBOX" in
  off|auto|require) ;;
  *)
    echo "Error: Invalid SPEC_SANDBOX value '$SPEC_SANDBOX' (expected: off|auto|require)." >&2
    exit 1
    ;;
esac

SANDBOX_MODE="off"
SANDBOX_STATUS="disabled"
EGRESS_LOG_PATH=""
SANDBOX_PREFIX=()

has_preflight_blockers() {
  local json_out="$1"
  [[ -z "$json_out" ]] && return 0
  if command -v jq >/dev/null 2>&1; then
    local count
    count="$(printf '%s' "$json_out" | jq -r '(.blockers // []) | length' 2>/dev/null || echo "1")"
    [[ "$count" != "0" ]] && return 0
    return 1
  else
    python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if not d.get("blockers") else 1)' <<< "$json_out" 2>/dev/null && return 1 || return 0
  fi
}

if [[ "$SPEC_SANDBOX" != "off" ]]; then
  case "$PROVIDER" in
    agy|claude|codex)
      if ! command -v ai-jail >/dev/null 2>&1; then
        if [[ "$SPEC_SANDBOX" == "require" ]]; then
          echo "🛑 Sandbox Error: 'ai-jail' binary not found on PATH (SPEC_SANDBOX=require)." >&2
          exit 78
        fi
        SANDBOX_STATUS="fallback-missing-binary"
      else
        set +e
        PREFLIGHT_JSON="$(ai-jail --harness "$PROVIDER" status --json -- "$PROVIDER" 2>/dev/null)"
        PREFLIGHT_EXIT=$?
        set -e
        if [[ "$PREFLIGHT_EXIT" -ne 0 ]] || has_preflight_blockers "$PREFLIGHT_JSON"; then
          if [[ "$SPEC_SANDBOX" == "require" ]]; then
            echo "🛑 Sandbox Error: ai-jail preflight reported blockers for '$PROVIDER' in '$TARGET_CWD' (exit $PREFLIGHT_EXIT). Run: ai-jail configure $PROVIDER" >&2
            exit 78
          fi
          echo "⚠️ Sandbox Notice: ai-jail profile not configured for '$PROVIDER' in '$TARGET_CWD'; falling back to unjailed run." >&2
          SANDBOX_STATUS="fallback-unconfigured"
        else
          SANDBOX_MODE="ai-jail"
          SANDBOX_STATUS="enforced"
          SANDBOX_PREFIX=(ai-jail --harness "$PROVIDER" --no-save-config --mask '.env' --mask '.env.*')
          if [[ -f ".git" ]]; then
            SANDBOX_PREFIX+=(--worktree)
          fi
          if [[ "$MODE" == "plan" ]]; then
            SANDBOX_PREFIX+=(--no-toolchains)
          fi
          if [[ -n "${SPEC_SANDBOX_EXTRA_HOSTS:-}" ]]; then
            IFS=',' read -ra EXTRA_HOSTS_ARR <<< "$SPEC_SANDBOX_EXTRA_HOSTS"
            for h in "${EXTRA_HOSTS_ARR[@]}"; do
              [[ -n "$h" ]] && SANDBOX_PREFIX+=(--allow-host "$h")
            done
          fi
          if [[ "${SPEC_SANDBOX_EGRESS_LOG:-1}" == "1" ]] && [[ "$(uname -s)" == "Linux" ]]; then
            EGRESS_DIR="${SPEC_EGRESS_LOG_DIR:-$HOME/.cache/spec-harness-kit/egress}"
            mkdir -p "$EGRESS_DIR" 2>/dev/null || true
            EGRESS_LOG_PATH="$EGRESS_DIR/$(date -u +%Y%m%dT%H%M%SZ)-$$.jsonl"
            SANDBOX_PREFIX+=(--egress-log "$EGRESS_LOG_PATH")
          fi
          SANDBOX_PREFIX+=(--)
        fi
      fi
      ;;
    *)
      if [[ "$SPEC_SANDBOX" == "require" ]]; then
        echo "🛑 Sandbox Error: Provider '$PROVIDER' is not supported by ai-jail --harness (SPEC_SANDBOX=require)." >&2
        exit 78
      fi
      SANDBOX_STATUS="fallback-unsupported-provider"
      ;;
  esac
fi

now_ms() {
  date +%s%3N 2>/dev/null || echo "$(( $(date +%s) * 1000 ))"
}
START_MS=$(now_ms)

resolve_agy_model() {
  local tier="$1"
  local suffix override fallback
  case "$tier" in
    cheap)    suffix="low";    override="${SPEC_AGY_MODEL_CHEAP:-}";    fallback="gemini-4-hydrogen-low" ;;
    standard) suffix="medium"; override="${SPEC_AGY_MODEL_STANDARD:-}"; fallback="gemini-4-hydrogen-medium" ;;
    frontier) suffix="high";   override="${SPEC_AGY_MODEL_FRONTIER:-}"; fallback="gemini-4-hydrogen-high" ;;
    *) echo "Unknown tier: $tier" >&2; return 1 ;;
  esac

  if [[ -n "$override" ]]; then
    printf '%s' "$override"
    return 0
  fi

  local cache_dir="${SPEC_MODEL_CACHE_DIR:-$HOME/.cache/spec-harness-kit}"
  local cache_file="$cache_dir/agy-models.txt"
  local ttl="${SPEC_MODEL_CACHE_TTL_SEC:-3600}"
  local now_sec mtime age=999999

  if [[ -f "$cache_file" ]]; then
    now_sec="$(date +%s)"
    mtime="$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)"
    age=$(( now_sec - mtime ))
  fi

  if [[ ! -s "$cache_file" ]] || [[ "$age" -ge "$ttl" ]]; then
    mkdir -p "$cache_dir" 2>/dev/null || true
    local raw_models
    raw_models="$(timeout 8s agy models 2>/dev/null | tr '\r' '\n' | awk '/^[a-z0-9][a-z0-9.-]+[[:space:]]+/ { print $1 }' || true)"
    if [[ -n "$raw_models" ]]; then
      printf '%s\n' "$raw_models" > "$cache_file" 2>/dev/null || true
    fi
  fi

  local picked=""
  if [[ -s "$cache_file" ]]; then
    local -a prefs=()
    if [[ "$tier" == "frontier" ]]; then
      prefs=("${SPEC_AGY_FRONTIER_FAMILY:-hydrogen}" "neon" "argon")
    else
      prefs=("hydrogen" "flash")
    fi

    local fam
    for fam in "${prefs[@]}"; do
      picked="$(grep -E "^gemini-.*${fam}.*-${suffix}$" "$cache_file" | grep -v "orchestrator" | head -n 1 || true)"
      [[ -n "$picked" ]] && break
    done

    if [[ -z "$picked" ]]; then
      picked="$(grep -E "^gemini-.*-${suffix}$" "$cache_file" | grep -v "orchestrator" | head -n 1 || true)"
    fi
  fi
  printf '%s' "${picked:-$fallback}"
}

# 6. Execute provider with timeout and stripped MCP/subagent overhead
set +e
case "$PROVIDER" in
  agy)
    case "$TIER" in
      cheap)    EFFORT="low" ;;
      standard) EFFORT="medium" ;;
      frontier) EFFORT="high" ;;
      *) echo "Unknown tier: $TIER" >&2; exit 1 ;;
    esac
    MODEL="$(resolve_agy_model "$TIER")"
    AGY_MODE=$([[ "$MODE" == "plan" ]] && echo "plan" || echo "accept-edits")
    # CRITICAL: --print="$PROMPT" must be attached and placed last so agy does not swallow flags
    timeout "${TIMEOUT_SEC}s" "${SANDBOX_PREFIX[@]}" agy \
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
    printf '%s' "$PROMPT" | timeout "${TIMEOUT_SEC}s" "${SANDBOX_PREFIX[@]}" claude \
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
    printf '%s' "$PROMPT" | timeout "${TIMEOUT_SEC}s" "${SANDBOX_PREFIX[@]}" codex \
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
    printf '%s' "$PROMPT" | timeout "${TIMEOUT_SEC}s" "${SANDBOX_PREFIX[@]}" hermes chat \
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

# 7. Structured JSONL Telemetry (disable with SPEC_DISABLE_TELEMETRY=1)
if [[ "${SPEC_DISABLE_TELEMETRY:-0}" != "1" ]]; then
  TELEMETRY_LOG="${SPEC_TELEMETRY_LOG:-$HOME/.cache/spec-harness-kit/telemetry.jsonl}"
  mkdir -p "$(dirname "$TELEMETRY_LOG")" 2>/dev/null || true
  TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"timestamp":"%s","provider":"%s","tier":"%s","mode":"%s","agent":"%s","prompt_chars":%d,"duration_ms":%d,"exit_code":%d,"sandbox_mode":"%s","sandbox_status":"%s","egress_log":"%s"}\n' \
    "$TS" "$PROVIDER" "$TIER" "$MODE" "$AGENT" "${#PROMPT}" "$DURATION_MS" "$WORKER_EXIT" "$SANDBOX_MODE" "$SANDBOX_STATUS" "$EGRESS_LOG_PATH" >> "$TELEMETRY_LOG" 2>/dev/null || true
fi

# 8. Non-Destructive Read-Only Verification Tripwire
if [[ "$MODE" == "plan" ]] && [[ "$IN_GIT_REPO" -eq 1 ]]; then
  POST_STATUS=$(git status --porcelain; git diff --binary HEAD 2>/dev/null | sha256sum)
  if [[ "$PRE_STATUS" != "$POST_STATUS" ]]; then
    echo "⚠️ Security Alert: Read-only worker violated plan mode and modified working tree state!" >&2
    git status --short >&2
    exit 2
  fi
fi

exit "$WORKER_EXIT"
