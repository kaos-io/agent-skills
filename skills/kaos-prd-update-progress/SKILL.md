---
name: kaos-prd-update-progress
description: Update PRD acceptance criteria statuses, threat statuses, and open question statuses based on completed implementation work. Uses KAOS MCP to verify criteria against real platform state where possible.
user-invocable: true
---

# KAOS PRD Update Progress

Update the PRD to reflect completed implementation work. This skill analyses what was done, verifies acceptance criteria against real platform state where the MCP can help, proposes status updates for ACs, threats, and open questions, and commits the progress checkpoint.

**Verification-first — only mark things passed when there is evidence, not assumption.**

## Usage

```
/kaos-prd-update-progress
/kaos-prd-update-progress [issue-id]
```

## Process

---

### Step 1: Identify PRD and Scope of Work

Detect the active PRD from context:
1. Conversation context — recent implementation discussion
2. Current branch: `feature/prd-[N]-*`
3. Recently modified `knowledge/prds/*.md`
4. Ask the user

Then understand what was completed. Use in this order:
1. **Conversation context** — what the user said was done
2. **Git log** — recent commits on the current branch
3. **Git diff** — files modified

```bash
git log --oneline -n 20
git diff --name-status main...HEAD
```

Build a list of completed work items to map against the PRD.

---

### Step 2: Acceptance Criteria Verification

For each `AC-NN` row with `status: pending` or `status: failed`, determine if it can now be marked `passed`.

**Verification tiers — use the highest tier available:**

#### Tier 1: MCP Verification (strongest — use when available)

Some ACs can be verified against real platform state. Use the MCP for these:

**Provisioning time ACs** (e.g., "KubePool provisions in <25 minutes"):
If an operation ID is available from recent work:
```
kaos:status(operation_id="[id]")
```
Check `durationMinutes` in the response against the AC threshold.

**Resource existence ACs** (e.g., "KubePool, KubeProject, KubeApp are namespaced"):
```
kaos:list(resource_type="KubePool")
kaos:list(resource_type="KubeProject")
```
Verify the response matches what the AC claims.

**Platform state ACs** (e.g., "No naming collision between two KubeOrgs"):
```
kaos:list(resource_type="KubeOrg")
```
Cross-reference with AC verification method.

**Knowledge base ACs** (e.g., architecture or documentation claims):
```
kaos:knowledge(query="[topic the AC asserts is true]")
```

#### Tier 2: Git Evidence (medium — use when Tier 1 is not applicable)

Map git changes to ACs:

| AC type | Git evidence that supports passing |
|---|---|
| File exists | `git diff --name-status` shows file created |
| Code pattern eliminated | `git log` shows commit message referencing the pattern |
| Linter passes | CI log or commit message references passing lint |
| Test passes | Commit message or test output references specific test name |

**Conservative rule:** Git evidence supports passing but does not prove it unless the AC's `How to Verify` method matches what the git evidence shows.

#### Tier 3: Conversation Assertion (weakest — use only when explicit)

If the user explicitly states "AC-NN is passing" or "I've verified [specific criterion]" — accept it with a note that it was asserted, not MCP-verified.

**Never auto-pass ACs based on inference alone.** If a feature's code was merged but the AC says "Timed end-to-end: apply KubePool → Ready" and no timing data exists — it stays `pending`.

---

### Step 3: Threat Status Updates

For each `T-NN` with `status: open`, check if the mitigation has been implemented:

- If the mitigation was "code review gate" and the linter/review process is now in place — propose `mitigated`
- If the mitigation was a time-box or deadline and that mechanism is now active — propose `mitigated`
- If the threat condition has been permanently resolved (e.g., the CRD migration was completed and the old cluster-scoped resources are gone) — propose `closed`

**Distinction:**
- `mitigated` = the mitigation is in place but the risk still exists if the mitigation is ever removed
- `closed` = the threat condition can no longer occur regardless of what the team does

---

### Step 4: Open Question Resolution

For each `Q-N` with `status: open`, check if the answer is now known:

- From conversation context: did the user state an answer?
- From implementation: did the code make a specific choice that answers the question?
- From git: does a committed ADR or config file answer it?

If resolved, propose:
```
status: resolved
resolution: "[one sentence answer — what was decided]"
```

If the question was made irrelevant by a scope change:
```
status: deferred
resolution: "Out of scope — [reason]"
```

---

### Step 5: Present Proposed Updates

Present all proposed changes for confirmation before writing anything:

```markdown
## PRD Progress Update — #[issue-id]

### Acceptance Criteria

| AC | Current | Proposed | Evidence | Tier |
|---|---|---|---|---|
| AC-NN | pending | ✅ passed | [specific evidence] | MCP / Git / Asserted |
| AC-NN | pending | pending | [what is still missing] | — |
| AC-NN | pending | ❌ failed | [what failed and why] | MCP / Git |

### Threats

| Threat | Current | Proposed | Reason |
|---|---|---|---|
| T-NN | open | mitigated | [mitigation now active] |

### Open Questions

| Q | Current | Proposed | Resolution |
|---|---|---|---|
| Q-N | open | resolved | [answer] |

### Overall Progress

- ACs passing: [N] / [total]
- Threats mitigated/closed: [N] / [total]
- Open questions resolved: [N] / [total]
- Estimated completion: [N]%

### What Is Still Missing

[Explicit list of what still needs to be done before PRD can be marked implemented.
Be honest — do not say "almost done" if multiple critical ACs are still pending.]

---

Confirm these updates? Type 'yes' to apply, or correct any item above.
```

Wait for confirmation. Apply only confirmed items.

---

### Step 6: Apply Updates to PRD File

After confirmation, update the PRD file:

1. Update each confirmed AC row — change `status` field in the table
2. Update each confirmed threat row — change `status` field
3. Update each confirmed open question row — change `status` and add `resolution`
4. Update front matter `last_updated` to today
5. If all critical ACs are now `passed` — propose changing front matter `status: active` → `status: implemented`

---

### Step 7: Commit Progress

Stage all changes — PRD updates AND any implementation files together as one atomic commit:

```bash
git add .
git status   # verify what will be committed

git commit -m "feat(prd-[issue-id]): [brief description of completed work]

PRD Progress:
- ACs passed: [list AC-NN refs]
- Threats mitigated: [list T-NN refs]  
- Questions resolved: [list Q-N refs]
- Overall: [N]% complete

Refs #[issue-id]"
```

Do not push unless the user explicitly requests it.

---

### Step 8: Next Steps

**If PRD has remaining work:**

```
PRD progress updated and committed.

To continue: run /kaos-prd-next
```

**If all critical ACs are now passed:**

```
All critical acceptance criteria are passing.
PRD #[issue-id] is ready for completion.

To finalise: run /kaos-prd-complete
```

---

## Verification Reference — Current PRD ACs

When verifying ACs from PRD-OP-0.1 specifically, use these MCP mappings:

| AC | MCP verification method |
|---|---|
| AC-04: Router dispatches by provider | `kaos:list(resource_type="KubePool")` — check cloudProvider field exists |
| AC-05: CRDs are namespaced | `kaos:list(resource_type="KubePool")` — check namespace field in response |
| AC-06: KubePool provisions <25min | `kaos:status(operation_id=...)` — check durationMinutes |
| AC-07: No naming collision | `kaos:list(resource_type="KubePool")` — look for duplicate names across orgs |

All other ACs (AC-01 through AC-03, AC-08 through AC-12) require git or assertion evidence — they cannot be MCP-verified.
