---
name: code-review
description: Conducts multi-axis, forensic code review for Pull Requests (GitHub/GitLab) or local branch diffs. Dispatches specialized subagents, deduplicates previous comments, checks PRD/RFC traceability, and enforces Addy Osmani's 5-axis quality standard (Correctness, Readability, Architecture, Security, Performance).
---

# Code Review & Quality Assurance

Comprehensive multi-dimensional code review with quality gates. Every change gets reviewed before merge — no exceptions. This skill guides the agent to review Pull Requests via CLI (`gh`/`glab`) or local branch diffs against fixed references, orchestrating specialist subagents and applying the **Addy Osmani 5-Axis Quality Framework** with structural remedies.

---

## 🎯 The Five-Axis Review & Approval Standard

The approval standard: **Approve a change when it definitely improves overall code health, even if it isn't perfect.** Do not block changes on personal preference or bikeshedding. If it improves the codebase and adheres to project conventions and architectural harnesses, approve it.

### The Five Axes:
1. **Correctness:** Does the code match PRD/RFC requirements? Are edge cases handled (null, empty, boundary, disconnects)? Are tests validating true domain invariants?
2. **Readability & Simplicity:** Can another engineer understand this without author explanation? Are control flows direct? Could this be done with less complexity?
3. **Architecture:** Clean module boundaries, explicit DIP, no circular dependencies. Does this refactor reduce complexity or merely relocate it?
4. **Security:** Zero secrets or hardcoded token fallbacks. Input validation and sanitization at system boundaries. RBAC authorization and OWASP compliance.
5. **Performance & Algorithm:** No $N+1$ query patterns, sequential cache/database loops, unconstrained pagination, memory leaks, or metric cardinality explosion.

### Structural Remedies:
When flagging an architectural or design issue, **always propose the structural remedy**, not just a critique:
- Replace conditional chains with typed models or explicit dispatchers.
- Collapse duplicate branches into a single unified flow.
- Separate orchestration from pure business logic.
- Move feature-specific logic out of shared modules into the owning domain package.
- Make type boundaries explicit so downstream defensive branching disappears.
- Delete pass-through wrappers that only add pointless indirection.

---

## 🔄 Execution Workflow

### 1. Ingest Input (PR URL or Local Diff)
- **GitHub PR URL:** Extract repository (`-R <repo>`) and PR number (`<id>`).
  - Run `gh pr view <id> -R <repo>`
  - Run `gh pr diff <id> -R <repo>`
  - Run `gh pr view <id> -R <repo> --comments` (MANDATORY for deduplication)
- **Local Diff:** Run `git diff <fixed-point>...HEAD` and `git log <fixed-point>..HEAD --oneline`.

### 2. Audit Prior Comments & De-duplication
- Inspect all existing comments from human reviewers and automated bots (e.g. Lobão Tech).
- Check if prior feedback was already resolved in the latest commits.
- **NEVER repeat existing comments** in the report. Focus on verifying prior points, identifying new critical issues, or catching regressions.

### 3. Initialize Review Progress Matrix
```markdown
- [ ] 1. Extraction of Diff, Metadata, and Prior Comments
- [ ] 2. Audit of Prior Comments & De-duplication
- [ ] 3. Security Review (security-reviewer)
- [ ] 4. High-Level Design Review (architecture-reviewer)
- [ ] 5. Low-Level Design & SOLID Review (lld-reviewer)
- [ ] 6. Algorithm & Complexity Review (algorithm-complexity-reviewer)
- [ ] 7. Frontend Stack Review (angular-reviewer / frontend-reviewer - if applicable)
- [ ] 8. Backend Stack Review (backend-reviewer - if applicable)
- [ ] 9. QA & Test Value Review (qa-reviewer)
- [ ] 10. Database Review (dba-reviewer - if SQL/ORM/Migrations present)
- [ ] 11. PRD/RFC Traceability & Final Report Consolidation
```

### 4. Dispatch Specialist Subagents
Dispatch the available subagents (`security-reviewer`, `architecture-reviewer`, `lld-reviewer`, `algorithm-complexity-reviewer`, `angular-reviewer`, `backend-reviewer`, `qa-reviewer`, `dba-reviewer`) providing the full diff, project context, and prior comments summary.

### 5. Check PRD & RFC Traceability
Look for originating PRD or RFC in the commit messages, `docs/prds/`, `docs/rfcs/`, or ClickUp links. Produce a requirements compliance matrix (`✅ Conforme`, `⚠️ Parcial`, `⚪ Omitido`).

### 6. Synthesize Final Report & ROI Table
Generate the consolidated report containing:
1. Executive Summary & QA Score (0-100)
2. Prior Comments Audit Table (Status: Atendido / Pendente)
3. New Critical Issues (P0) with exact code fixes
4. Improvement Points & Structural Remedies (P1/P2)
5. PRD & RFC Traceability Matrix
6. Positive Highlights
7. Prioritized ROI Action Table (Effort vs Impact)
8. Mermaid Sequence Diagram highlighting architectural gaps
