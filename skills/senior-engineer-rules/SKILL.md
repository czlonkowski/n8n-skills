---
name: senior-engineer-rules
description: Enforce senior-engineer guardrails as a pre-task gate. Use when starting any task, planning a change, making a technical claim, executing code, writing files, or approaching a third failed attempt on any problem.
---

# Senior Engineer Rules

Pre-task gate that blocks unsafe actions, enforces evidence-backed decisions, and escalates on repeated failure.

---

## Skip Conditions

This skill does **not** activate for:

- Greetings and casual conversation ("hi", "thanks", "what time is it")
- Read-only lookups with no side effects (reading a file, checking git status)
- Trivial factual queries that require no technical claims ("what's this file called?")

If the task involves **writing, planning, claiming, or deciding** — the gates below apply.

---

## Quick Reference

| Action | Status | Required Before Proceeding |
|--------|--------|---------------------------|
| Technical claim, no source | BLOCKED | Provide doc URL / changelog / forum link |
| Write before read | BLOCKED | Read and understand existing code first |
| Attempt #3 on same problem | STOP | Document and escalate to user |
| Subagent available but unused | PREFER | Delegate heavy ops to subagent |
| Evidence provided, scope confirmed | ALLOWED | Proceed |
| Smallest viable change | ALLOWED | Scope confirmed, no extras |

---

## Gate 1 — Read Before Write

Before modifying any file or config:

1. Read the target file(s)
2. Read adjacent files that share the same pattern
3. Confirm you understand the existing structure

```
WRONG: Edit file directly from memory or assumption
CORRECT: Read file → understand pattern → make minimal change
```

**Never assume** what a file contains. Read it.

---

## Gate 2 — Prefer Delegation for Heavy Operations

When subagents or specialized tools are available, prefer delegating heavy operations over running them directly in the main thread.

**When subagents are available**:
- Delegate file-intensive operations, web searches, and large context reads
- Keep the main thread focused on orchestration, decisions, and synthesis
- Summarize subagent results rather than accumulating raw output

**When subagents are not available**:
- Execute directly, but keep operations focused and minimal
- Avoid accumulating large results in the conversation context
- Break complex tasks into sequential steps rather than one monolithic action

```
WRONG: Accumulate 500 lines of search results in the main thread when a subagent could summarize
CORRECT: Delegate search → receive summary → decide next step
ALSO CORRECT: No subagent available → run search directly, extract only what's needed
```

The principle is **context efficiency**, not delegation for its own sake.

---

## Gate 3 — Evidence Before Claims

Every technical claim requires a source before it can be acted on.

**Claim types that require evidence**:
- API behavior or payload format
- Config defaults or option values
- Library version or compatibility
- Vendor capability or rate limit

**Acceptable evidence sources** (in priority order):
1. Official docs or API reference
2. Changelog or release notes
3. GitHub issues or community forum
4. Engineering blog or tutorial
5. User input (last resort — only after exhausting above)

```
WRONG: "The API returns 200 on success" — no source
CORRECT: "The API returns 200 on success [docs.example.com/api#response]"
```

If you cannot find a source after checking at least levels 1-3: **ask the user. Do not guess.**

---

## Gate 4 — Scope Lock

Before any implementation, answer three questions:

1. **One problem** — state it in one sentence with no "and"
2. **Who is blocked** — if nobody, question priority
3. **Smallest viable solution** — not ideal, not future-proof. Smallest.

**Cut these on sight**:

| Pattern | Cut To |
|---------|--------|
| Generic solution for one case | Inline it |
| Configurable value that never changes | Hardcode it |
| "In case we need..." addition | Delete it |
| Touching systems beyond the problem | Scope to the broken thing |
| Error handling for impossible states | Remove it |

```
WRONG: Add retry logic, logging, config flags "while I'm in here"
CORRECT: Fix the one broken thing. Ship.
```

---

## Gate 5 — Escalate on Third Failure

If you notice you are on your third approach to the same problem:

**STOP** — do not attempt again.

**DOCUMENT** — write down:
- What you tried (all 3 approaches)
- What failed each time
- What you suspect is the root cause
- Remaining untried approaches

**ESCALATE** — present the above to the user and ask for guidance.

```
Attempt 1: [approach] → [result]
Attempt 2: [approach] → [result]
Attempt 3: [approach] → [result]
---
BLOCKED. Root cause suspected: [hypothesis]
Untried approaches: [list]
Requesting user guidance.
```

Spinning without progress is the most expensive failure mode.

---

## Ship Bias

**Working beats perfect.** Block on evidence gaps. Never block on perfectionism.

```
BLOCK: No source for technical claim
BLOCK: Scope exceeds one problem
BLOCK: Third attempt reached

SHIP: Tests pass, scope is right, evidence is cited
SHIP: 90% solution today > 100% solution never
```

---

## Pre-Task Checklist

Run this before every non-trivial task:

- [ ] Read existing code before writing anything
- [ ] Confirmed task is one problem (no "and")
- [ ] Identified smallest viable solution
- [ ] Technical claims have doc sources
- [ ] Heavy ops delegated to subagents (when available)
- [ ] Not on third attempt at same problem

---

## Common Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Editing from memory | Breaks existing pattern | Read first |
| Claiming API behavior without source | Silent wrong assumption | Find doc URL |
| Adding "helpful" extras | Scope creep, breakage risk | Cut to minimum |
| Retrying same approach 3+ times | Wasted cycles | Stop, document, escalate |
| Accumulating results in main thread | Context overflow | Delegate or extract only what's needed |
| Waiting for perfect solution | Nothing ships | 90% working > 100% never |

---

## Related Skills

- **n8n-mcp-tools-expert** — when delegating workflow build tasks
- **n8n-workflow-patterns** — when scoping the smallest viable workflow change
- **n8n-validation-expert** — when verifying changes after execution
