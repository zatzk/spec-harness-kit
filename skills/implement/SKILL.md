---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

**Bugfix / Regression Rule (Reproduce Red First):** If the work fixes a bug or regression, write a failing test or run a deterministic reproduction command and observe it fail (`RED`) *before* editing any production source file.

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and both the ticket's `Verify command` (if defined) and the full test suite once at the end.

Once done, call the Skill tool with "verify" (or "code-review" for diff-only PR review) before declaring complete.

Commit your work to the current branch at the slice's commit checkpoint.
