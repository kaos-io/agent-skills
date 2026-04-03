---
name: kaos-prd-sprint
description: PRD workflow orchestrator. Picks next AC, generates plan, delegates to agent, verifies, and auto-updates PRD progress. Replaces manual invocation of kaos-prd-next → plan → delegate → kaos-prd-update-progress.
user-invocable: true
---

# KAOS PRD Sprint

Orchestrates the full PRD implementation cycle in a single skill invocation. Instead of manually running `/kaos-prd-next`, crafting a plan, delegating to an agent, and then running `/kaos-prd-update-progress`, this skill handles the entire loop.

**One command. Pick AC → Plan → Approve → Delegate → Verify → Update PRD → Next AC.**

## Usage

```
/kaos-prd-sprint
/kaos-prd-sprint [issue-id]
```

## Process

---

### Step 1: Identify Active PRD

Follow the same detection logic as `kaos-prd-next`:

If `[issue-id]` is provided — use it directly.

If not — detect from context:
1. Current branch: `feature/prd-[N]-*` → use PRD N
2. Recent conversation: explicit PRD reference → use that
3. Modified `knowledge/prds/*.md` file → use that PRD
4. Ask the user

Read the full PRD file. Build an internal model of all features, ACs, threats, and open questions with their statuses.

---

### Step 2: Pick Next AC

Scan for the highest-priority unimplemented acceptance criterion.

**Priority order** (same as `kaos-prd-next`):
1. Fix a **failing** AC — broken things take absolute priority
2. **Critical-path** feature AC — `Defer? = ❌`, dependencies met, lowest feature number
3. Resolve **blocking open question** — if Q-N blocks the next critical-path item
4. **High-leverage** feature AC — unlocks the most downstream work
5. **Parallel-safe** AC — can run alongside current work

**Query platform state to validate the pick:**
```
kaos:list(resource_type="KubeOrg")
kaos:list(resource_type="KubePool")
kaos:knowledge(query="[topic relevant to the AC]")
```

**Present the selection:**

```markdown
## Next: [AC-NN — Criterion Title]

**From Feature:** F-NN — [Feature Name]

**Why this AC:**
[2-3 sentences — why this is highest priority right now]

**Platform state:**
[What MCP queries confirmed — prerequisites exist, resources are ready, etc.]

**Dependencies satisfied:**
[List prerequisite features/ACs and confirm they pass]

**Constraints to respect:**
[CON-NN constraints that apply]

Confirm to proceed with planning?
```

Wait for user confirmation. If the user wants a different AC, switch to it.

---

### Step 3: Generate Plan

Using the selected AC, produce a plan in the standard format:

```markdown
# Plan: [AC-NN — Title]

## Objective
[What this AC achieves, traced back to the PRD feature]

## Acceptance Criteria
[Copy the exact AC text from the PRD — this is what must pass]

## Questions
[Uncertainties — do not assume. If none, state "None."]

## Constraints
[CON-NN constraints from the PRD that apply to this work]

## Implementation Steps
1. [Ordered steps with file paths]
2. [...]

## Verification
- [ ] [How to verify the AC passes]
- [ ] [Additional checks]

## Files to Modify
- `path/to/file` — [what changes]
```

---

### Step 4: Single Approval Gate

Present the plan. Wait for explicit approval.

This is the **only** approval gate in the entire sprint cycle. No further approvals needed for delegation or PRD updates.

---

### Step 5: Delegate

After approval, determine the right agent based on the AC's domain:

| AC Domain | Agent |
|-----------|-------|
| Operator/controller code | Developer agent |
| Crossplane compositions | Developer agent |
| Frontend/dashboard | Frontend agent |
| API endpoints | Developer agent |
| E2E/integration testing | @kaos-tester agent |

**Spawn the agent** with `model: sonnet` (Sonnet 4.6) and the full approved plan.

Include in the agent prompt:
- The exact AC text from the PRD
- Relevant constraints (CON-NN)
- File paths from the plan
- Framework patterns from CLAUDE.md
- Instruction to run tests after implementation

---

### Step 6: Post-Implementation Verification

After the agent completes, verify the work:

1. **Run the verification steps** from the plan
2. **Check the AC** — does the implementation satisfy the exact criterion text?
3. **Run relevant tests** — `make test`, composition tests, or manual verification

**Present results:**

```markdown
## Verification: AC-NN

| Check | Result | Evidence |
|-------|--------|----------|
| [Verification step] | ✓/✗ | [command output or observation] |
| [Test suite] | ✓/✗ | [test results] |

**Verdict:** PASSED / FAILED
```

**If PASSED:**
- Auto-update the PRD: mark AC-NN as `passed`
- Follow the same process as `/kaos-prd-update-progress`:
  - Update the AC status in the PRD file
  - Commit the PRD update
  - Output confirmation

**If FAILED:**
- Present the failure details
- Ask the user:
  - **Retry** — go back to Step 5 with additional context about the failure
  - **Modify plan** — go back to Step 3 with adjusted approach
  - **Skip** — mark as `pending` and move to next AC

---

### Step 7: Loop or Stop

After completing an AC:

```markdown
## Sprint Progress

| AC | Status | Time |
|----|--------|------|
| AC-01 | ✓ Passed | [timestamp] |
| AC-02 | ✗ Skipped | [timestamp] |

**Continue to next AC?**
```

- If **yes** → return to Step 2 with updated PRD model
- If **no** → output sprint summary:

```markdown
## Sprint Summary

**PRD:** [PRD title]
**ACs completed:** [count]
**ACs skipped:** [count]
**ACs remaining:** [count]

**Next recommended AC:** [from Step 2 analysis]

Run `/kaos-prd-sprint` again to continue where you left off.
```

---

## Key Differences from Manual Workflow

| Manual | Sprint |
|--------|--------|
| `/kaos-prd-next` → read recommendation | Automatic AC selection |
| Manually craft plan | Auto-generated from AC |
| "pass to @agent-developer" | Auto-delegation by domain |
| Wait, then `/kaos-prd-update-progress` | Auto-verification and update |
| 4 skill invocations per AC | 1 skill invocation per sprint session |
