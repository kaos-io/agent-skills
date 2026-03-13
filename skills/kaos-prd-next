---
name: kaos-prd-next
description: Analyse current PRD state and platform reality to identify and recommend the single highest-priority task to work on next. Uses KAOS MCP to verify platform state before making recommendations.
user-invocable: true
---
 
# KAOS PRD Next
 
Identify the single highest-priority task to work on next for an active PRD. This skill reads the PRD, queries real platform state via the KAOS MCP where relevant, and recommends one task with clear rationale. It then enters a design discussion if the user confirms.
 
**One recommendation at a time. Always wait for confirmation before designing.**
 
## Usage
 
```
/kaos-prd-next
/kaos-prd-next [issue-id]
```
 
## Process
 
---
 
### Step 1: Identify Active PRD
 
If `[issue-id]` is provided — use it directly.
 
If not — detect from context:
1. Current branch: `feature/prd-[N]-*` → use PRD N
2. Recent conversation: explicit PRD reference → use that
3. Modified `knowledge/prds/*.md` file → use that PRD
4. Ask the user
 
Read the full PRD file. Build an internal model of:
- Which features (`F-NN`) have all their ACs passing
- Which ACs are `pending`, `failed`, or `blocked`
- Which threats are `open` and `critical`
- Which open questions are `open` and have `Due: During F-NN`
 
---
 
### Step 2: Platform State Query
 
Before making any recommendation, query actual platform state. This prevents recommending tasks that cannot be started because their infrastructure prerequisites do not exist.
 
**Query sequence — run these in order, stop when you have enough context:**
 
```
kaos:list(resource_type="KubeOrg")
```
Reveals: which organisations exist and their status. Required before recommending any KubePool or KubeProject-level work.
 
```
kaos:list(resource_type="KubePool")
```
Reveals: which clusters exist, their cloudProvider, their status. Required before recommending compositions that target a specific pool.
 
If the PRD involves specific feature knowledge (e.g., Cilium, Crossplane, ArgoCD behaviour):
```
kaos:knowledge(query="[topic relevant to the task being evaluated]")
```
 
**Map findings to PRD features:**
 
| Platform finding | PRD impact |
|---|---|
| No KubeOrg with `cloudProvider: gcp` | Any feature requiring GCP pool cannot be started |
| KubePool in `Failed` state | Features that add to that pool are blocked |
| Knowledge base contradicts a PRD assumption | Flag before recommending the dependent feature |
 
---
 
### Step 3: Dependency Analysis
 
For each pending feature, evaluate:
 
**Can it be started now?**
- All `Depends On` features are complete (ACs passing)
- Required platform state exists (Step 2)
- No blocking open questions with `Due: Before F-NN start`
 
**What does it unlock?**
- Count how many other features list this in their `Depends On`
- Features that unlock 3+ others are high-leverage
 
**Is it on the critical path to the business gate?**
- Cross-reference `business_gate` in front matter
- Features with `Defer? = ❌` that are not yet started are highest priority
 
**Classify each startable feature:**
 
| Class | Criteria |
|---|---|
| `critical-path` | `Defer? = ❌`, not started, all dependencies met |
| `high-leverage` | Unlocks 2+ other features |
| `parallel-safe` | Can run alongside current work, different owner |
| `blocked` | Dependencies not met or platform state missing |
| `deferred` | Explicitly marked `Defer? = ✅` and lower value now |
 
---
 
### Step 4: Select Single Best Task
 
Apply this priority order:
 
1. **Fix a failing acceptance criterion** — if any AC is `failed`, fixing it takes absolute priority over starting new work. A failing AC means something believed complete is broken.
 
2. **Critical-path feature not yet started** — `Defer? = ❌`, all dependencies met, lowest feature number (follow the dependency chain order).
 
3. **Resolve an open question blocking the next critical-path feature** — if Q-N has `Due: Before F-NN start` and F-NN is the next critical-path item, resolving the question is the task.
 
4. **High-leverage feature** — unlocks the most downstream work.
 
5. **Parallel-safe work** — if a critical-path item is already in progress and a parallel-safe feature exists, recommend that as a secondary option.
 
**Never recommend:**
- A feature whose dependencies are not complete
- Work that contradicts a `CON-NN` constraint — check Section 5 before recommending anything
- Work on a feature that has an unresolved blocking open question
 
---
 
### Step 5: Present Recommendation
 
```markdown
# Next Task: [Feature Name or AC Fix]
 
## Recommended: [F-NN — Feature Title] or [Fix AC-NN — Criterion]
 
**Why this task:**
[2-3 sentences. Why is this the highest-priority right now? Reference the
dependency chain, business gate, or platform state finding that drives the priority.]
 
**What it unlocks:**
[What becomes possible after this is done. Name specific downstream features or ACs.]
 
**Platform state check:**
[What the MCP query confirmed — e.g., "KubeOrg 'infinite-orbits' is Ready,
KubePool dependency is satisfied" or "No GCP KubePool exists yet — this
feature creates the foundation."]
 
**Dependencies satisfied:**
[List features this depends on and confirm they are complete.]
 
**Constraints to respect:**
[List any CON-NN constraints that apply to this work. The agent must not
violate these during implementation.]
 
**Acceptance criteria to target:**
[List the AC-NN rows from the PRD that this task should drive to `passed`.]
 
---
 
Confirm to proceed? I will design the implementation approach.
If you want a different task, tell me which feature or AC to focus on instead.
```
 
Wait for user confirmation. Do not proceed to design without it.
 
---
 
### Step 6: Implementation Design (After Confirmation)
 
Once the user confirms, provide:
 
**Architecture approach:**
How this task fits into the existing codebase based on the PRD's target file structure (Section 8). Reference specific files to create or modify.
 
**Key interfaces and patterns:**
Reference the relevant `CON-NN` constraints and `D-NN` decisions. Name the Go interfaces, Crossplane composition patterns, or CRD fields involved.
 
**Step-by-step breakdown:**
Logical implementation sequence. Each step should be independently testable.
 
**How to verify completion:**
Map each implementation step to the specific `AC-NN` row it satisfies. When all mapped ACs pass, the task is done.
 
**Risks during implementation:**
Reference relevant `T-NN` threats from the PRD. What to watch for.
 
---
 
### Step 7: After Implementation
 
**Do not update the PRD yourself.**
 
After the user completes implementation work, output only:
 
```
Implementation complete.
 
To update PRD progress and commit your work, run /kaos-prd-update-progress.
```
 
Then stop.
