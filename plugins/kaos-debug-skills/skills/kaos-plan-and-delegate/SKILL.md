---
name: kaos-plan-and-delegate
description: Streamlined plan-then-delegate workflow. Generates plans with acceptance criteria and no assumptions, waits for single approval, then auto-spawns the right agent type. All agents default to Sonnet 4.6.
user-invocable: true
---

# KAOS Plan and Delegate

Consolidates the "craft a plan → approve → pass to agent" workflow into a single skill invocation. Produces plans in the user's preferred format (numbered acceptance criteria, questions instead of assumptions) and delegates to the appropriate agent after a single approval gate.

**One plan. One approval. One delegation. No back-and-forth.**

## Usage

```
/kaos-plan-and-delegate
/kaos-plan-and-delegate [description of the task]
```

## Process

---

### Step 1: Intake and Domain Detection

Gather the user's request. If insufficient context, ask targeted questions — but never assume.

**Determine the work domain** to select the right agent later:

| Domain | Signals | Agent Target |
|--------|---------|-------------|
| **Operator** | Go code, CRDs, controllers, reconciliation, phases, builders | Developer agent (sonnet) |
| **Compositions** | XRDs, Crossplane, compositions, patches, providers | Developer agent (sonnet) |
| **Frontend** | React, TypeScript, dashboard, UI, components | Frontend agent (sonnet) |
| **API** | kaos-graph, kaos-gitops-gateway, REST endpoints | Developer agent (sonnet) |
| **Testing** | E2E, integration test, platform validation | @kaos-tester agent (sonnet) |
| **PRD-driven** | Acceptance criteria, feature from PRD, sprint work | Defer to `/kaos-prd-sprint` |
| **Infrastructure** | Scripts, Helm charts, cluster operations | Developer agent (sonnet) |

If the domain is **PRD-driven**, tell the user to use `/kaos-prd-sprint` instead and stop.

**Query platform context if relevant:**
```
kaos:knowledge(query="[topic relevant to the task]")
kaos:schema(resource_type="[relevant resource]")
```

---

### Step 2: Plan Generation

Generate the plan in this exact format:

```markdown
# Plan: [Title — concise, action-oriented]

## Objective
[1 sentence: what this achieves and why it matters]

## Acceptance Criteria
1. **AC-01:** [Verifiable condition — not "should work" but "X returns Y when Z"]
2. **AC-02:** [Another verifiable condition]
3. **AC-03:** [...]

## Questions
[List EVERY uncertainty. Do not assume answers. If there are no questions, state "None — requirements are clear."]

- Q1: [Question about ambiguous requirement]
- Q2: [Question about implementation choice]

## Constraints
[Only constraints the user has explicitly stated or that are documented in CLAUDE.md/PRD]

## Implementation Steps
1. [Step with dependency noted if applicable]
2. [Next step]
3. [...]

## Verification
- [ ] [How to verify AC-01]
- [ ] [How to verify AC-02]
- [ ] [...]

## Files to Modify
- `path/to/file.go` — [what changes]
- `path/to/file.yaml` — [what changes]
```

**Rules:**
- Acceptance criteria must be objectively verifiable (not subjective)
- Questions section is mandatory — if you have zero questions, you probably missed something
- Implementation steps must be ordered by dependency
- Include file paths when known
- Do not pad with unnecessary steps — keep it lean

---

### Step 3: Approval Gate

Present the plan to the user. Wait for explicit approval.

**Acceptable approval signals:** "approved", "go", "do it", "ship it", "yes", "lgtm"

**If the user has modifications:**
1. Incorporate the changes
2. Re-present the updated plan
3. Wait for approval again

**Do NOT proceed without clear approval.** Ambiguous responses like "hmm ok" or "I guess" are not approval — ask for clarification.

---

### Step 4: Agent Delegation

After approval, spawn the appropriate agent:

**Agent selection** (from Step 1 domain detection):

- Use the Agent tool with `model: "sonnet"` (Sonnet 4.6) unless the user specifies otherwise
- Pass the full approved plan as the agent's task description
- Include relevant file paths and context the agent will need
- For operator work: include the framework architecture pattern from CLAUDE.md
- For composition work: include the composition directory structure
- For testing: use the `@kaos-tester` agent definition

**Agent prompt template:**
```
You are implementing the following approved plan:

[Full plan from Step 2]

Key context:
- [Relevant CLAUDE.md patterns]
- [Relevant existing code patterns]
- [Any answers to questions from the plan]

Implementation rules:
- Follow the acceptance criteria exactly
- Run tests after implementation
- Do not make assumptions — if unclear, list what you need clarified
```

**For multi-domain work** (e.g., operator + compositions):
- Spawn parallel agents if the work is independent
- Use sequential agents if one depends on the other
- Clearly scope each agent's responsibility

---

### Step 5: Handoff Summary

After delegation, output a summary:

```markdown
## Delegated

| Aspect | Detail |
|--------|--------|
| **Agent** | [agent type] (Sonnet 4.6) |
| **Scope** | [what was delegated] |
| **ACs to deliver** | AC-01, AC-02, AC-03 |
| **Files** | [key files being modified] |

The agent is now working on the implementation. Review its output against the acceptance criteria when complete.
```

Then stop. Do not continue working — the agent handles implementation.
