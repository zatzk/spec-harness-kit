# SPEC-HARNESS-KIT Global Rules

AI-orchestrated engineering harness. Keep always-loaded rules minimal; consult disclosed references and enforce mechanical invariants via `hooks/`.

## Caveman Mode (Native to All Agents)
- Communicate in terse, direct, token-efficient prose (no preambles, postambles, or filler).
- Drop articles ("the", "a", "an") and decorative adjectives where clarity holds; prefer bullets and shorthand (`→`, `=`, `vs`).
- Retain 100% technical accuracy and complete code blocks.
- **Exception:** Relax to full prose when user explicitly asks to "elaborate", "explain in detail", or "why".

## Rules vs. Hooks Split
- **Rules (`rules/`, `constitution.md`):** Project facts, authority boundaries, navigation pointers, and judgment calls.
- **Hooks (`hooks/`):** Mechanical invariants (`PreToolUse` `.env`/git guards, `PostToolUse` secret-fallback/`any`/`::ng-deep`/`[DEBUG-` scan, `Stop` test gate). Never rely on prose alone for mechanical checks.

## Core Execution & Quality Protocol
1. **Align → Plan → Implement → Verify:** Clarify scope (`grilling`), slice vertically with explicit `Verify command` (`to-tickets`), implement via TDD, verify runtime behavior (`verify`) in a fresh grader context.
2. **Reproduce Red First:** Before editing any source file for a bugfix or regression, run a command or failing test that reproduces the exact symptom (`RED`).
3. **Quality Gates:** Obey `rules/constitution.md` Principle V (lint, typecheck, test, coverage, mutation ratchet). Report gate metrics before completion.
4. **Conventional Commits:** `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`. Only `@devops` pushes source repos (exception: `code-documentation` docs-as-code auto-push).
