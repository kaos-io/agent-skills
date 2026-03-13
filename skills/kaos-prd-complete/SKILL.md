---
name: kaos-prd-complete
description: Finalise a PRD that is fully implemented or close one that is no longer needed. Archives the PRD file, updates the GitHub issue with a completion summary, and closes the issue. Two modes - implemented and closed.
user-invocable: true
---

# KAOS PRD Complete

Finalise the lifecycle of a PRD. This skill handles two distinct scenarios with a shared workflow: a PRD that has been fully implemented (all critical ACs passing), and a PRD that is being closed without full implementation (superseded, out of scope, already implemented elsewhere, or deferred indefinitely).

The distinction matters because the knowledge base must accurately represent why a PRD stopped — "implemented" and "closed without implementation" are different states that the extraction pipeline treats differently.

## Usage

```
/kaos-prd-complete [issue-id]
/kaos-prd-complete [issue-id] implemented
/kaos-prd-complete [issue-id] closed "reason"
```

## Mode Selection

If the mode is not specified, the skill determines it automatically:

- If all `AC-NN` rows with critical features have `status: passed` → **implemented mode**
- If any critical AC is still `pending` or `failed` → **ask the user to confirm** whether they intend to close without full implementation

```markdown
⚠️ Not all critical acceptance criteria are passing:

| AC | Status | Feature |
|---|---|---|
| AC-NN | pending | F-NN (Critical) |

Are you closing this PRD as:
1. **Implemented** — all requirements are satisfied (override AC status)
2. **Closed** — closing without full implementation (provide reason)
```

---

## Mode A: Implemented

### Step 1: Final Verification

Run a final MCP state check for any ACs that can be verified against real platform state:

```
kaos:list(resource_type="KubePool")
kaos:list(resource_type="KubeProject")
```

Cross-reference with ACs that claim these resources exist or behave in a specific way. Flag any mismatch as a last warning before closing.

Present final AC summary:

```markdown
## Final Verification — PRD #[issue-id]

| AC | Status | Verification |
|---|---|---|
| AC-NN | ✅ passed | MCP verified / Git evidence / Asserted |
| AC-NN | ✅ passed | ... |

**All [N] critical acceptance criteria: PASSING**

Threats:
- [N] mitigated, [N] closed, [N] still open (expected ongoing)

Open questions:
- [N] resolved, [N] deferred

Ready to mark as implemented.
```

### Step 2: Update PRD File

Update front matter:
```yaml
status: implemented
last_updated: [today's date]
implemented_date: [today's date]
prd_version: [final version]
```

Update any remaining `status: pending` ACs that the user has confirmed are satisfied. Update threat statuses if mitigations are now permanent.

### Step 3: Archive PRD File

```bash
mkdir -p knowledge/prds/done
git mv knowledge/prds/[issue-id]-[name].md knowledge/prds/done/[issue-id]-[name].md
```

### Step 4: Update GitHub Issue Body

```bash
gh issue edit [issue-id] --body "$(cat <<'EOF'
## PRD: [Feature Name]

### Business Context
[Copy from original issue — do not change]

### What Was Built
[Updated summary of what was actually implemented — may differ from original plan]

### Implementation Outcome

| Requirement | Status |
|---|---|
| [F-NN: Feature name] | ✅ Implemented |
| [F-NN: Feature name] | ✅ Implemented |
| [F-NN: Deferred feature] | ⏸️ Deferred to Phase N |

### Key Decisions Made
[Bullet list of the most important architectural decisions — 3-5 items]

### What Changed From Original Plan
[Honest summary of scope changes, deferred items, or decisions that evolved.
If nothing changed: "Implemented as specified."]

---

**PRD Archive**: See [knowledge/prds/done/[issue-id]-[name].md](./knowledge/prds/done/[issue-id]-[name].md)
**Status**: ✅ IMPLEMENTED
**Implemented**: [Date]
EOF
)"
```

### Step 5: Close GitHub Issue

```bash
gh issue close [issue-id] --comment "$(cat <<'EOF'
## ✅ PRD #[issue-id] Implemented

**[Feature Name]** is complete.

### What Was Delivered

[2-3 sentences describing what the implementation produced. Business-readable.]

### Acceptance Criteria Summary

| AC | Criterion | Verified By |
|---|---|---|
| AC-NN | [criterion] | MCP / Git / Test |
| AC-NN | [criterion] | MCP / Git / Test |

### Key Architectural Decisions

- **[D-NN]**: [Decision title] — [one sentence on what was decided and why it matters]
- **[CON-NN]**: [Constraint title] — [one sentence on what is now enforced]

### What Was Deferred

[If nothing: "All scope was delivered as specified."]
[If something: list features with `Defer? = ✅` and which future phase they move to]

### PRD Archive

`knowledge/prds/done/[issue-id]-[name].md`

Implemented: [Date]
EOF
)"
```

---

## Mode B: Closed (Without Full Implementation)

### Step 1: Capture Closure Reason

**Closure reason categories:**

| Category | When to use |
|---|---|
| `superseded` | Another PRD or decision replaces this one |
| `already-implemented` | Functionality exists elsewhere (link required) |
| `out-of-scope` | Requirements changed and this no longer aligns |
| `deferred-indefinitely` | Valid but not prioritised — no target phase |
| `duplicate` | Covered by another active PRD (reference required) |

The closure reason must be specific. "No longer needed" is not a sufficient reason — it must explain *why* it is no longer needed.

### Step 2: Update PRD File

Update front matter:
```yaml
status: closed
last_updated: [today's date]
closed_date: [today's date]
closure_reason: "[category]: [one sentence explanation]"
prd_version: [final version]
```

Add a closure note at the top of the PRD body, immediately after front matter:

```markdown
> **CLOSED — [Date]**
> **Reason**: [closure reason category] — [explanation]
> **Reference**: [link to superseding PRD, external implementation, or other reference]
> This PRD is archived for historical context. The decisions and rationale documented here
> remain valid as product knowledge even though implementation did not proceed.
```

**Do not delete content.** Rationale sections, constraints, and rejected alternatives in a closed PRD are still valid knowledge for the RAG pipeline. An agent asking "why was X approach considered and rejected?" should still find that answer even in closed PRDs.

### Step 3: Archive PRD File

```bash
mkdir -p knowledge/prds/done
git mv knowledge/prds/[issue-id]-[name].md knowledge/prds/done/[issue-id]-[name].md
```

### Step 4: Update GitHub Issue Body

```bash
gh issue edit [issue-id] --body "$(cat <<'EOF'
## PRD: [Feature Name]

### Business Context
[Copy from original — do not change]

### Why This Was Closed
[2-3 sentences. Plain language. What changed that made this PRD no longer needed or no longer accurate?]

### What Was Implemented (If Anything)
[Be honest — if nothing was implemented, say so. If partial work was done, describe it.]

### Where to Look Instead
[If superseded: link to superseding PRD]
[If already implemented: link to external implementation]
[If out of scope: brief note on what direction was taken instead]

---

**PRD Archive**: See [knowledge/prds/done/[issue-id]-[name].md](./knowledge/prds/done/[issue-id]-[name].md)
**Status**: ⏸️ CLOSED — [closure reason category]
**Closed**: [Date]
EOF
)"
```

### Step 5: Close GitHub Issue

```bash
gh issue close [issue-id] --comment "$(cat <<'EOF'
## ⏸️ PRD #[issue-id] Closed — [Closure Reason Category]

**Reason**: [Full explanation — 2-4 sentences. Why now. What changed. What happens instead.]

[If superseded]
**Superseded by**: PRD #[N] — [link]

[If already implemented elsewhere]
**Implementation reference**: [repo/PR/link]

**What this means for the knowledge base:**
The architectural rationale and constraints documented in this PRD remain valid product knowledge
and will continue to be retrievable via the RAG pipeline from the archive location.

PRD archived: `knowledge/prds/done/[issue-id]-[name].md`
Closed: [Date]
EOF
)"
```

---

## Shared Final Step: Commit and Push

```bash
git add .
git status  # verify PRD moved to done/, no other changes

git commit -m "docs(prd-[issue-id]): [implemented|close] PRD #[issue-id] - [feature-name] [skip ci]

- Status: [active|implemented] → [implemented|closed]
- Archived: knowledge/prds/done/[issue-id]-[name].md
- GitHub issue #[issue-id] closed
- [One line summary of outcome]

Closes #[issue-id]"

git pull --rebase origin main && git push origin main
```

---

## Status Transition Reference

```
draft
  ↓ /kaos-prd-start
active
  ↓ /kaos-prd-complete (all critical ACs passing)
implemented  →  archived to knowledge/prds/done/

active
  ↓ /kaos-prd-complete (closure mode)
closed  →  archived to knowledge/prds/done/

draft
  ↓ /kaos-prd-complete (closure mode — never started)
closed  →  archived to knowledge/prds/done/
```

**Reasoning behind the distinction:**
`implemented` tells future agents "this was built — look for it in the codebase."
`closed` tells future agents "this was considered but not built — the rationale still applies."
Both states preserve knowledge. Neither deletes content.

## Notes

- The `PRD` label on the GitHub issue must remain even after closure. The Argo Workflow extraction pipeline uses it to determine which issues to process. A closed issue with the `PRD` label will have its archive location extracted into the knowledge base.
- Do not remove the `PRD` label during closure — only the status changes.
- If the PRD file is deleted rather than archived, the knowledge base loses its rationale chunks permanently. Always move to `done/`, never delete.
