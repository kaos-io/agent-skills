---
name: kaos-prd-create
description: Create a new KAOS PRD file with RAG-optimised structure, open a GitHub issue with business summary, and apply the correct labels to trigger the extraction pipeline.
user-invocable: true
---
 
# KAOS PRD Create
 
Create a new Product Requirements Document for the KAOS platform. This skill produces two artefacts: a structured markdown PRD file at `knowledge/prds/[number]-[name].md` and a GitHub issue that serves as the permanent tracker for the PRD lifecycle. The GitHub issue label triggers the Argo Workflow extraction pipeline automatically — correct labelling is mandatory, not optional.
 
## When to Use
 
- A new feature, architectural decision, or platform capability needs a PRD
- A conversation or design session has produced enough clarity to formalise intent
- A business or delivery gate requires documented requirements before implementation begins
 
## Process
 
---
 
### Step 1: Gather Intent
 
Ask the user to describe the feature or change. You need enough to write the business context and scope. Minimum viable input:
 
- What problem does this solve?
- Who is affected (client, team, platform)?
- What business gate or delivery date is this tied to?
- Which part of the KAOS hierarchy is involved (KubeOrg / KubePool / KubeProject / KubeApp / operator / OSR / NOUS)?
 
If the user mentions CRD fields, spec changes, or composition modifications — call `kaos:schema` for the relevant resource type before writing any requirements. The schema is the ground truth for what fields exist, their types, validation rules, and immutability constraints. Do not write requirements that contradict the schema.
 
```
kaos:schema(resource_type="KubePool")   # if pool-level changes are involved
kaos:schema(resource_type="KubeProject") # if project-level changes are involved
```
 
If the user mentions existing platform behaviour or tooling — call `kaos:knowledge` to retrieve accurate context before writing the problem statement.
 
```
kaos:knowledge(query="[topic from user description]")
```
 
---
 
### Step 2: Create GitHub Issue First
 
Create the issue immediately to get the issue number. The issue number is the PRD file name prefix — you cannot name the file without it.
 
**Issue body template:**
 
```markdown
## PRD: [Feature Name]
 
### Business Context
[2-3 sentences. What business problem or opportunity does this address?
Which client or gate is it tied to? What happens if it is not delivered?]
 
### What We Are Building
[2-3 sentences. Plain language description of what will be built or changed.
No technical jargon — this should be readable by a non-engineer stakeholder.]
 
### Why Now
[1-2 sentences. What makes this the right time to do this work?
Reference the specific business gate, delivery milestone, or dependency chain.]
 
### Scope in One Line
[Single sentence. What is explicitly in scope vs explicitly out of scope.]
 
### Key Decisions Made
[Bullet list of 2-5 architectural or product decisions already resolved.
If none yet, write "No decisions made — see PRD for open questions."]
 
### Acceptance Signal
[1-2 sentences. How will we know this is done? Reference the primary
acceptance criterion or business sign-off condition.]
 
---
 
**Detailed PRD**: Will be linked after file creation.
 
**Phase**: [Phase 0 / Phase 1 / etc.]
**Owner**: [Name]
**Business Gate**: [Gate name and date]
**Status**: 🟡 Draft
```
 
**Create the issue:**
```bash
gh issue create \
  --title "PRD: [Feature Name]" \
  --body "[body from template above]" \
  --label "PRD"
```
 
**If the PRD label does not exist, create it first:**
```bash
gh label create "PRD" \
  --description "Product Requirements Document — triggers RAG extraction pipeline" \
  --color "0052CC"
```
 
**Capture the issue number from the output.** This is `[issue-id]` for all subsequent steps.
 
---
 
### Step 3: Create PRD File
 
Create the file at `knowledge/prds/[issue-id]-[kebab-case-name].md`.
 
The file must include valid YAML front matter — the extraction pipeline reads this to classify chunks. Use the schema defined in the KAOS RAG documentation guidelines.
 
**Required front matter:**
 
```yaml
---
title: "[Full PRD title]"
document_id: "PRD-[COMPONENT]-[issue-id]"
prd_version: 0.1.0
status: draft
audience: technical
difficulty: advanced
topics:
  - [topic-1]
  - [topic-2]
phase: "[Phase N — Phase Name]"
business_gate: "[Gate name — Date]"
owner: "[Name]"
github_issue: [issue-id]
last_updated: [YYYY-MM-DD]
extracted_chunks:
  - architectural-decision
  - architectural-rationale
  - feature-requirement
  - constraint
  - acceptance-criterion
  - threat
  - open-question
---
```
 
**PRD section structure** — follow this order, do not invent new top-level sections:
 
```
## 1. Business Context
## 2. Problem Statement
### 2.1 Identified Gaps
## 3. Architectural Rationale — Why We Made These Choices
### 3.N [One subsection per rationale topic — 150-350 tokens each]
## 4. Goals & Non-Goals
### 4.1 Goals
### 4.2 Non-Goals
## 5. Constraints
### CON-NN — [Constraint title]
[One subsection per constraint — each must include: Statement, Why it exists, Enforcement, Refs]
## 6. Architectural Decisions
### D-NN — [Decision title]
[One subsection per decision — each must include: options table, recommendation, rationale]
## 7. Feature Requirements
[Table with columns: Ref | Feature | Owner | Effort | Priority | Defer? | Decision Refs | Rationale Refs | Description]
## 8. Target File / System Structure
## 9. Acceptance Criteria
[Table with columns: Ref | Criterion | How to Verify | Status]
## 10. Threat Register
[Table with columns: ID | Threat | Severity | Status | Features | Mitigation]
## 11. Validation Strategy
## 12. Dependency Chain
## 13. Effort Summary
## 14. Open Questions
[Table with columns: # | Question | Why It Matters | Owner | Due | Status]
```
 
**Token sizing rules** (from KAOS RAG guidelines — mandatory):
- Each `###` subsection: 100–400 tokens (~75–300 words)
- No `###` section below 50 tokens (will be filtered by pipeline)
- No `###` section above 500 tokens (will be force-split)
- Each `##` section including all children: 50–2000 tokens
- Code blocks: <30 lines. Mermaid diagrams are exempt.
- Tables: <10 rows, or convert to prose subsections
 
**Status field initial values:**
- All Acceptance Criteria: `pending`
- All Threats: `open`
- All Open Questions: `open`
 
---
 
### Step 4: Update GitHub Issue with PRD Link
 
Now that the file exists, update the issue body to add the PRD link:
 
```bash
gh issue edit [issue-id] --body "$(cat <<'EOF'
[previous body content — copy exactly]
 
---
 
**Detailed PRD**: See [knowledge/prds/[issue-id]-[name].md](./knowledge/prds/[issue-id]-[name].md)
EOF
)"
```
 
**Verify the label is applied:**
```bash
gh issue view [issue-id] --json labels
```
 
The `PRD` label must be present. If missing, apply it:
```bash
gh issue edit [issue-id] --add-label "PRD"
```
 
The label is what triggers the Argo Workflow extraction pipeline. Without it, the RAG knowledge base will not be updated.
 
---
 
### Step 5: Commit and Push
 
```bash
git add knowledge/prds/[issue-id]-[name].md
 
git commit -m "docs(prd-[issue-id]): create PRD #[issue-id] - [feature-name] [skip ci]
 
- Created PRD: [one-line description]
- Defined [N] features, [N] constraints, [N] acceptance criteria
- GitHub issue #[issue-id] labelled PRD — extraction pipeline triggered
 
Refs #[issue-id]"
 
git pull --rebase origin main && git push origin main
```
 
Always use `[skip ci]` — PRD file creation does not require a CI run.
 
---
 
### Step 6: Present Summary
 
```markdown
✅ PRD Created
 
**File**: knowledge/prds/[issue-id]-[name].md
**GitHub Issue**: #[issue-id]
**Label**: PRD ✅ (extraction pipeline will trigger on next sync)
 
**Features defined**: [N]
**Constraints**: [N]
**Acceptance criteria**: [N]
**Open questions**: [N]
 
**Next steps**:
- Resolve open questions before starting implementation
- Run `/kaos-prd-start [issue-id]` when ready to begin
- Architectural decisions require sign-off before coding starts
```
 
---
 
## Schema Validation Rules
 
When writing feature requirements that involve CRD changes, validate against schema:
 
| Claim type | Validation |
|---|---|
| New field on a CRD | Confirm field does not already exist in schema |
| Immutability claim | Cross-check against schema `updatePolicy.immutable` |
| Validation rule | Cross-check against schema `validator` field |
| Default value | Cross-check against schema `default` field |
 
If a feature requirement contradicts the schema, flag it as an open question before writing it as a requirement.
 
## Notes
 
- The `knowledge/prds/` path is the canonical location. Do not use `prds/` at the repo root.
- The GitHub issue body is the human-readable summary — keep it non-technical and business-readable.
- The PRD file is the technical source of truth — it can be dense.
- Do not include implementation code in the PRD. The PRD describes what and why, not how at code level.
- The extraction pipeline reads `extracted_chunks` from the front matter to classify chunk types. If a new chunk type is needed, it must be added to the front matter before the pipeline runs.
