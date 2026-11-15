#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: enforces deterministic git authority & .env protection.
# Reads Claude/Agy-style hook JSON from stdin and exits 2 on policy violation.

INPUT="$(cat || true)"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

extract_field() {
  local jq_expr="$1"
  local py_key="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r "$jq_expr // empty" 2>/dev/null || true
  else
    python3 -c "import json,sys; d=json.load(sys.stdin); ti=d.get('tool_input') or {}; print(ti.get('$py_key','') or '')" <<< "$INPUT" 2>/dev/null || true
  fi
}

COMMAND="$(extract_field '.tool_input.command' 'command')"
FILE_PATH="$(extract_field '.tool_input.file_path // .tool_input.path' 'file_path')"
if [[ -z "$FILE_PATH" ]]; then
  FILE_PATH="$(extract_field '.tool_input.path' 'path')"
fi

# 1. Block .env file reads/writes (except safe templates)
is_sensitive_env_path() {
  local target="$1"
  [[ -z "$target" ]] && return 1
  if printf '%s' "$target" | grep -qE '(^|/)\.env(\.(example|template|sample))$'; then
    return 1
  fi
  if printf '%s' "$target" | grep -qE '(^|/)\.env(\.(local|development|production|staging|test))?$'; then
    return 0
  fi
  return 1
}

if is_sensitive_env_path "$FILE_PATH"; then
  echo "BLOCKED: Access to sensitive environment file '$FILE_PATH' is prohibited by security policy." >&2
  exit 2
fi

if [[ -n "$COMMAND" ]]; then
  # Block shell commands reading or writing .env files (excluding .env.example/.template/.sample)
  SANITISED_CMD="$(printf '%s' "$COMMAND" | sed -E 's/\.env\.(example|template|sample)\b/__SAFE_ENV__/g')"
  if printf '%s' "$SANITISED_CMD" | grep -qE '(^|[[:space:]/'\''"])\.env(\.(local|development|production|staging|test))?($|[[:space:]'\''";|&])'; then
    echo "BLOCKED: Command references sensitive .env file: '$COMMAND'." >&2
    exit 2
  fi

  # 2. Block dangerous git commands & unauthorized git push
  DANGEROUS_PATTERNS=(
    'git[[:space:]]+reset[[:space:]]+--hard'
    'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f'
    'git[[:space:]]+branch[[:space:]]+-D'
    'git[[:space:]]+checkout[[:space:]]+\.'
    'git[[:space:]]+restore[[:space:]]+\.'
    'push[[:space:]]+--force'
  )

  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if printf '%s' "$COMMAND" | grep -qE "$pattern"; then
      echo "BLOCKED: '$COMMAND' matches dangerous git pattern '$pattern'." >&2
      exit 2
    fi
  done

  if printf '%s' "$COMMAND" | grep -qE '(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]]|$)'; then
    if [[ "${SPEC_AGENT_ROLE:-}" != "devops" ]] && ! printf '%s' "$COMMAND" | grep -qE 'git[[:space:]]+-C[[:space:]]+([^[:space:]]*/)?code-documentation([[:space:]]|$)'; then
      echo "BLOCKED: Only @devops may run 'git push' on source repositories (exception: code-documentation docs-as-code)." >&2
      exit 2
    fi
  fi
fi

exit 0
