---
name: verify
description: Verify implemented work across 5 levels (lint/typecheck, unit, integration, runtime user-perspective execution, and pre-live readiness) using a fresh grader context. Use after implementing a ticket/spec or before deployment.
---

# Verify (Runtime & Independent Grading)

Verify completed work against real execution and user behavior—never rely solely on self-reported code edits or builder-authored mocks. **"The model never marks its own homework."**

## Rules

1. **Deterministic Checks First:** Run code-based checks (lint, typecheck, unit, integration, mutation) before invoking any LLM grading.
2. **Independent Grader:** When grading acceptance criteria that code cannot check alone (UX, end-to-end behavior, runtime logs), dispatch a **fresh grader context** (`spec-worker-dispatch standard plan qa ...` or an isolated subagent) given only the spec/acceptance criteria and disk/runtime artifacts—never the builder's conversation history.
3. **No Ad-Hoc Patching:** If verification fails due to a spec/design mismatch, record the exact failing artifact/output and route back to Align/Plan rather than applying blind workarounds.
4. **OS-Sandboxed Execution (`ai-jail` when available):** When `ai-jail` is installed on the host, execute untrusted project test suites, build scripts, and property-based fuzzers inside a credential-free, network-fenced jail (`ai-jail --no-agent-state --no-network --no-save-config --mask '.env' --mask '.env.*' [--forward-port <PORT>] -- <verify_cmd>`). This guarantees zero access to host LLM credentials (`~/.claude`, `~/.gemini`, `~/.codex`) or external network endpoints during verification.

## 5-Level Verification Ladder

Run levels in order; stop and report on first blocking failure:

1. **Level 1 — Static & Type Boundaries:** Run project lint, typecheck, and build commands.
2. **Level 2 — Unit & Mutation Assertions:** Run unit test suite (plus mutation testing ratchet via `quality-gate` where configured).
3. **Level 3 — Integration & Contract Boundaries:** Run integration/DB/DTO schema tests (Testcontainers, OpenAPI/Zod checks) plus stateful property/model checks (e.g., `fast-check`, TLA+/Quint) when the spec involves state machines, locks, or concurrent workflows.
4. **Level 4 — Runtime User-Perspective Execution & Artifact Bundle:**
   - Identify the real entrypoint (CLI binary, local HTTP server, or UI dev server).
   - Drive the feature as a user would (CLI fixture run, `curl`/HTTP assertions, or headless Playwright/Chrome DevTools Protocol script).
   - Assert **zero uncaught browser console errors** and **zero unexpected HTTP 5xx responses** alongside live stdout/stderr, server logs, and persisted DB/file state.
   - Emit a **Verification Artifact Bundle** (e.g., `.verify-artifacts/` containing before/after screenshots, sanitized runtime logs, and test/mutation metrics) so human reviewers can verify proof artifacts via `/pr` instead of reading raw diffs line-by-line.
5. **Level 5 — Pre-Live Security & Backup Gate (when `--pre-live` or releasing):**
   - Read and execute [`PRE-LIVE-CHECKLIST.md`](PRE-LIVE-CHECKLIST.md).
