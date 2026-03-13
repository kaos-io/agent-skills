---
name: kaos-prd-update-decisions
description: Capture architectural decisions, design changes, and strategic choices made during implementation or design conversations. Updates the PRD's decision log, rationale sections, constraints, and open questions. Validates new decisions against KAOS schemas.
user-invocable: true
---

# KAOS PRD Update Decisions

Capture design decisions, architectural changes, and strategic choices made during conversations or implementation work and reflect them in the PRD. This skill ensures the PRD remains the source of truth as decisions evolve — it does not let decisions live only in conversation history.

**Every significant decision made during implementation must be recorded here before the PRD is considered accurate.**

## Usage

```
/kaos-prd-update-decisions
/kaos-prd-update-decisions [issue-id]
```

## When to Use

- A design conversation has produced a resolution to an architectural question
- An open question has been answered and the answer changes how something will be built
- A constraint was discovered during implementation that was not in the PRD
- A feature's scope or approach changed from what was originally documented
- An alternative was evaluated and rejected — the rejection reasoning should be preserved
- A CRD field, spec structure, or composition approach was revised

## Process

---

### Step 1: Identify PRD and Decision Context

Detect the PRD from context (branch, conversation, file).

Then identify what decision(s) need to be captured. Look for:

**Explicit decision patterns in conversation:**
- "We decided to..."
- "The approach will be..."
- "We rejected X because..."
- "This changes the plan for..."
- "We now know that..."
- "The constraint is..."

**Implicit decision patterns:**
- A specific implementation choice was made (Go struct design, interface name, config approach)
- A feature's scope was reduced or expanded
- A dependency was discovered or removed
- A PRD assumption was proven wrong by implementation

For each decision identified, extract:
- What was decided
- What alternatives were considered (even informally)
- Why this option was chosen
- What it affects in the PRD (which features, constraints, ACs, threats)

---

### Step 2: Schema Validation

If the decision involves CRD changes, new fields, or spec modifications — validate against the schema before writing it into the PRD.

```
kaos:schema(resource_type="[affected resource]")
```

**Validation checks:**

| Decision claim | What to verify |
|---|---|
| "Add field X to KubePool" | Does field X already exist? What type should it be? |
| "Field Y is immutable" | Confirm against `updatePolicy.immutable` in schema |
| "Default value is Z" | Confirm against schema `default` field |
| "Remove field W" | Check if W is referenced by other resources via schema |

If the decision contradicts the schema, flag it explicitly in the update. A decision that contradicts the schema is an open question until the schema is updated, not a resolved decision.

If the decision involves platform behaviour — validate via knowledge base:
```
kaos:knowledge(query="[topic the decision is about]")
```

---

### Step 3: Map Decision to PRD Sections

For each decision, determine which PRD sections need updating:

| Decision type | Sections to update |
|---|---|
| New architectural choice | `## 3. Architectural Rationale` — add/extend `### 3.N` subsection |
| Option resolved from `## 6. Architectural Decisions` | Update decision block status, mark recommendation as accepted |
| New constraint discovered | `## 5. Constraints` — add `### CON-NN` |
| Existing constraint strengthened | Update `CON-NN` statement or enforcement mechanism |
| Open question answered | `## 14. Open Questions` — mark resolved, add resolution |
| Feature scope change | `## 7. Feature Requirements` — update description, decision refs |
| New risk identified | `## 10. Threat Register` — add `T-NN` row |
| Risk mitigated by decision | Update `T-NN` status and mitigation description |
| AC verification method changed | `## 9. Acceptance Criteria` — update `How to Verify` |

---

### Step 4: Present Proposed Updates

Show all proposed changes before writing:

```markdown
## Decisions Captured — PRD #[issue-id]

### Decision: [Title]

**What was decided:** [One sentence]

**Alternatives rejected:**
- [Option A] — rejected because [reason]
- [Option B] — rejected because [reason]

**Rationale:** [2-3 sentences. Why this option. What would break if we chose differently.]

**Schema validation:** [Confirmed against kaos:schema / Not applicable / CONFLICT — see note]

**PRD changes required:**

| Section | Change |
|---|---|
| `## 3. Architectural Rationale` | Add `### 3.N [title]` — [summary of content] |
| `## 5. Constraints` | Add `CON-NN — [title]` — [statement] |
| `## 6. Architectural Decisions` | Mark `D-NN` as `accepted` |
| `## 14. Open Questions` | Resolve `Q-N` — resolution: "[answer]" |

---

[Repeat block for each decision]

---

Confirm these updates? Type 'yes' to apply all, or specify which to apply.
```

---

### Step 5: Apply Updates

After confirmation, apply each change:

**For new rationale subsections:**
Rationale subsections must be 100–400 tokens. Write them self-contained — they must make sense when retrieved in isolation by the RAG pipeline. Include:
- What was challenged or questioned
- What was decided
- Why alternatives were rejected
- What would break if this decision were reversed

**For new constraints:**
Every `CON-NN` must include:
- Statement (what is prohibited or required)
- Why it exists (reference rationale section)
- Enforcement mechanism (code-review / linter / test / runtime)
- Cross-references to rationale and feature sections

**For decision status updates:**
Change `status: proposed` → `status: accepted` or `status: superseded` with `superseded_by: [D-NN]`.

**For new threats:**
Follow the existing threat table format. Include severity, initial status of `open`, affected features, and concrete mitigation.

**For open question resolution:**
Add `resolution: "[answer]"` field to the table row. Change `status: open` → `status: resolved`.

---

### Step 6: Update Front Matter

Update:
```yaml
last_updated: [today's date]
prd_version: [increment patch version, e.g. 0.1.0 → 0.1.1]
```

Increment the version on every decision update so the extraction pipeline knows the document changed.

---

### Step 7: Commit

```bash
git add knowledge/prds/[issue-id]-[name].md

git commit -m "docs(prd-[issue-id]): capture design decisions - [brief summary] [skip ci]

Decisions captured:
- [D-NN or decision title]: [one line]
- [CON-NN or constraint title]: [one line]
- [Q-N resolved]: [one line]

PRD version: [new version]
Refs #[issue-id]"

git pull --rebase origin main && git push origin main
```

Always use `[skip ci]` for PRD documentation updates.

---

## Decision Documentation Quality Standard

A well-documented decision in the rationale section must answer all four questions:

1. **What was challenged?** — What question or concern prompted the decision?
2. **What was decided?** — The specific choice made, stated unambiguously.
3. **Why were alternatives rejected?** — Not just "we preferred X" but what specifically breaks with Y.
4. **What is the invariant?** — What must remain true for this decision to remain valid? If this invariant is violated, the decision must be revisited.

Decisions that do not answer all four questions are not complete and will be flagged by the extraction pipeline as low-quality chunks.

## Notes

- Decisions made verbally in conversations have a half-life. If they are not written into the PRD within the same work session, they are likely to be lost or misremembered.
- The `invalidates` field on rationale chunks explicitly names rejected alternatives. Use it — it is what allows the agent to answer "why didn't we do X?" by retrieving the chunk that names X as rejected.
- A PRD that does not reflect current decisions is worse than no PRD. Stale decisions actively mislead agents.
