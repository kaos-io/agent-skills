---
name: kaos-prd-start
description: Validate PRD readiness, check platform state against requirements, create the implementation branch, and hand off to kaos-prd-next.
user-invocable: true
---
 
# KAOS PRD Start
 
Begin active implementation work on a specific PRD. This skill validates that the PRD is ready to be worked on — all blocking open questions resolved, all architectural decisions signed off — checks whether the current platform state is consistent with what the PRD assumes, creates the implementation branch, and hands off to `kaos-prd-next` for task selection.
 
**This skill is setup only. It does not recommend tasks or start implementation.**
 
## Usage
 
```
/kaos-prd-start [issue-id]
/kaos-prd-start 42
```
 
## Process
 
---
 
### Step 1: Locate the PRD
 
If `[issue-id]` is provided, read `knowledge/prds/[issue-id]-*.md` directly.
 
If not provided, detect from context in this order:
1. Current git branch — look for `feature/prd-[N]-*` pattern
2. Recently modified files — look for `knowledge/prds/*.md`
3. Ask the user
 
---
 
### Step 2: Readiness Validation
 
Read the PRD and evaluate against these gates. **All Critical gates must pass before proceeding.**
 
#### Critical Gates (blocking)
 
**Open questions resolved:**
Scan `## 14. Open Questions`. Any row with `Status: open` is a blocker unless it has `Due: During implementation` explicitly. If blocking open questions exist, list them and stop.
 
```markdown
⛔ Cannot start — [N] blocking open questions unresolved:
 
| # | Question | Owner | Due |
|---|---|---|---|
| Q-N | [text] | [owner] | [due] |
 
Resolve these before starting. Run `/kaos-prd-start` again after resolution.
```
 
**Architectural decisions signed off:**
Scan `## 6. Architectural Decisions`. Any decision with `status: proposed` (not `accepted`) is a blocker. List them and stop.
 
```markdown
⛔ Cannot start — [N] architectural decisions awaiting sign-off:
 
| ID | Decision | Owner |
|---|---|---|
| D-NN | [title] | [owner] |
 
Decisions must be confirmed before coding begins. Update decision status to 'accepted' in the PRD, then run `/kaos-prd-start` again.
```
 
**PRD status check:**
If front matter `status: closed` or `status: implemented` — stop. PRD is already complete.
 
#### Advisory Checks (non-blocking, reported)
 
- Features with `Defer? = ❌` that have unresolved `Decision Refs` — flag
- Threats with `severity: Critical` and `status: open` — flag
- Features with no acceptance criteria mapped — flag
 
---
 
### Step 3: Platform State Check
 
This step checks whether the current KAOS platform state is consistent with what the PRD assumes as its starting point. It uses the MCP to query real state — not documentation.
 
**Run these checks based on PRD content:**
 
If the PRD references existing KubeOrgs or KubePools as dependencies:
```
kaos:list(resource_type="KubeOrg")
kaos:list(resource_type="KubePool")
```
 
Compare results against what the PRD assumes exists. Flag mismatches:
 
```markdown
⚠️ Platform state mismatch detected:
 
PRD assumes: KubeOrg 'infinite-orbits' exists and is Ready
Actual state: [result from kaos:list]
 
This may affect: [feature refs that depend on this]
```
 
If the PRD references platform knowledge (e.g., Cilium CNI, ArgoCD version, Crossplane setup):
```
kaos:knowledge(query="[relevant topic]")
```
 
Use the result to validate that PRD assumptions about current platform behaviour are accurate. Flag if the knowledge base contradicts a PRD assumption.
 
**This step is informational — mismatches do not block start unless the mismatch means a prerequisite feature literally cannot be worked on.**
 
---
 
### Step 4: Update PRD Status
 
Update the front matter:
 
```yaml
status: active
last_updated: [today's date]
```
 
Commit this change:
 
```bash
git add knowledge/prds/[issue-id]-[name].md
git commit -m "docs(prd-[issue-id]): activate PRD #[issue-id] [skip ci]
 
- Status: draft → active
- All blocking gates passed
- Platform state verified
 
Refs #[issue-id]"
git pull --rebase origin main && git push origin main
```
 
---
 
### Step 5: Create Implementation Branch
 
```bash
git checkout main
git pull origin main
git checkout -b feature/prd-[issue-id]-[kebab-case-name]
git push -u origin feature/prd-[issue-id]-[kebab-case-name]
```
 
If already on a feature branch that matches this PRD — confirm and keep it. Do not create a duplicate.
 
---
 
### Step 6: Hand Off
 
Present the ready state and stop:
 
```markdown
## Ready for Implementation 🚀
 
**PRD**: [PRD title] (#[issue-id])
**Branch**: `feature/prd-[issue-id]-[name]`
**Status**: active
 
**Readiness summary**:
- Open questions: [N resolved / N total]
- Decisions signed off: [N/N]
- Platform state: [consistent / N mismatches flagged above]
 
**Features to implement**: [N critical, N high]
**Acceptance criteria**: [N pending]
 
---
 
To identify your first task, run `/kaos-prd-next`.
```
 
Do not proceed beyond this message. Do not recommend tasks. `kaos-prd-next` owns task selection.
 
