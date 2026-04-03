---
name: kaos-debug
description: Structured debugging that breaks the 3-5 iteration debug loop. Auto-gathers platform state, enforces root cause analysis before fixes, tracks attempts, and requires verification evidence.
user-invocable: true
---

# KAOS Debug

Structured debugging workflow that prevents circular fix-retry loops. This skill enforces a strict phase order: gather evidence, analyze root cause, propose fix, verify fix. It tracks every attempt to prevent repeating failed approaches.

**Never propose a fix before completing root cause analysis. Never claim a fix worked without verification evidence.**

## Usage

```
/kaos-debug
/kaos-debug [resource-type/name]
/kaos-debug [description of the issue]
```

## Process

---

### Phase 1: Auto-Gather Evidence

**Before the user describes the problem**, immediately run a parallel data collection sweep. This establishes baseline state and often reveals the issue without the user needing to paste logs.

**Run these in parallel:**

1. **Platform resource health:**
   ```
   kaos:list(resource_type="KubeOrg")
   kaos:list(resource_type="KubePool")
   kaos:list(resource_type="KubeProject")
   kaos:list(resource_type="KubeApp")
   ```
   Flag anything not in `Ready` state.

2. **Cluster events** (last 50, sorted by time):
   ```bash
   kubectl get events --sort-by=.lastTimestamp -A | tail -50
   ```

3. **Unhealthy pods:**
   ```bash
   kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded | head -30
   ```

4. **Current cluster context:**
   ```bash
   kubectl config current-context
   ```

5. **If a specific resource was named**, run diagnostics on it:
   ```
   kaos:diagnose(resource_type="<type>", name="<name>")
   kaos:get(resource_type="<type>", name="<name>")
   ```

6. **Operator logs** (last 30 lines):
   ```bash
   kubectl logs -n kubecore-system -l app=kubecore-operator --tail=30
   ```

Consult `references/debug-patterns.md` for known platform quirks that might explain the symptoms (e.g., status endpoint false-failures on delete, 95% stall pattern).

---

### Phase 2: Problem Statement

Present the gathered data to the user as a concise summary:

```markdown
## Gathered State

| Area | Finding |
|------|---------|
| Platform Resources | [summary of non-Ready resources] |
| Recent Events | [notable warnings/errors] |
| Unhealthy Pods | [count and notable pods] |
| Cluster Context | [which cluster we're on] |
| Operator Logs | [recent errors if any] |

**Which resource or behavior is the actual problem?**
[If obvious from the data, state your understanding and ask for confirmation]
```

Wait for the user to confirm the problem scope. Do not proceed without confirmation.

---

### Phase 3: Root Cause Analysis

**This phase is MANDATORY. You MUST NOT propose fixes until the RCA is confirmed.**

Produce a structured root cause analysis:

```markdown
## Root Cause Analysis

**Symptom:** [What is observed — the user's complaint + your evidence]

### Hypotheses

| # | Hypothesis | Evidence For | Evidence Against | Verdict |
|---|-----------|-------------|-----------------|---------|
| 1 | [Potential cause] | [What supports this] | [What contradicts this] | Likely / Unlikely / Needs investigation |
| 2 | [Another cause] | ... | ... | ... |
| 3 | [Another cause] | ... | ... | ... |

### Most Likely Root Cause

**[State the verdict]**: [1-2 sentences explaining why this is the most likely cause, referencing specific evidence]
```

**Rules:**
- Generate at least 2 hypotheses
- Each hypothesis must have both "Evidence For" AND "Evidence Against"
- If you cannot find evidence against a hypothesis, investigate deeper — easy answers are often wrong
- If a hypothesis requires checking something, check it now (run commands, read files) rather than guessing

Present the RCA and wait for the user to confirm the root cause before proceeding.

---

### Phase 4: Fix Proposal

Only after the user confirms the root cause:

```markdown
## Proposed Fix

**Root Cause:** [Confirmed cause]

**Fix:**
[Exact commands, code changes, or manifest modifications — be specific]

**Rollback Plan:**
[How to undo this fix if it makes things worse]

**Expected Outcome:**
[What should change after the fix is applied — specific conditions, log messages, or resource states]
```

Wait for user approval before applying the fix.

---

### Phase 5: Verification

After the fix is applied, **you must verify it worked**:

1. **Re-run the same data collection from Phase 1** — same commands, same queries
2. **Diff before vs after** — what actually changed?
3. **Check the Expected Outcome from Phase 4** — does the observed state match?
4. **Present evidence:**

```markdown
## Verification

| Check | Before | After | Pass? |
|-------|--------|-------|-------|
| [Resource Ready status] | [value] | [value] | ✓/✗ |
| [Operator logs] | [error] | [clean] | ✓/✗ |
| [Specific condition] | [state] | [state] | ✓/✗ |

**Result:** [RESOLVED / NOT RESOLVED]
```

If NOT RESOLVED, update the iteration tracker and return to Phase 3 with new evidence.

---

## Iteration Tracking

Maintain this table across all fix attempts within the session:

```markdown
## Debug Iteration Log

| Attempt | Hypothesis | Fix Applied | Result | Notes |
|---------|-----------|------------|--------|-------|
| 1 | [hypothesis] | [what was done] | [outcome] | [what we learned] |
| 2 | ... | ... | ... | ... |
```

**Critical rule:** If the iteration count reaches 3 without resolution:
- **STOP** proposing fixes from the same hypothesis family
- **Force pivot** to a fundamentally different hypothesis
- Consider: Are we debugging the right thing? Is the problem upstream?
- Suggest escalation options: check a different cluster, review recent git changes, or involve domain expertise

---

## Anti-Patterns to Avoid

1. **Never** say "this should fix it" without verification evidence
2. **Never** retry the exact same fix that already failed
3. **Never** skip the RCA phase because the fix seems obvious — obvious fixes that fail waste more time than careful analysis
4. **Never** assume which cluster context you're on — always check
5. **Never** ignore the iteration tracker — it prevents circular debugging
