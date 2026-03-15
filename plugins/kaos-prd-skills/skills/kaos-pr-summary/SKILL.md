---
name: kaos-pr-summary
description: Generate a structured PR summary for KAOS platform changes with PRD alignment and knowledge capture. Use when creating or reviewing pull requests.
user-invocable: true
---

# KAOS PR Summary

Generate a structured pull request summary that captures what changed, why, and what knowledge was created or consumed.

## Process

### Step 1: Gather Context

Identify:
- What files changed (read the diff or `git diff`)
- What resource types are affected (KubeOrg, KubePool, KubeProject, KubeApp)
- Whether there is an active PRD (check branch name for `prd-[N]` or commit messages for `Refs #N`)

If resource types are affected, fetch the schema:
```
kaos:schema(resource_type="[affected resource]")
```

If an active PRD exists, read the PRD file to map changes to acceptance criteria.

### Step 2: Generate Summary

Produce the following structured PR summary:

```markdown
## Summary
[2-3 bullet points. What was done and why. Lead with the business value.]

## Resource Impact

| Resource | Change Type | Fields Affected |
|---|---|---|
| [KubeOrg/KubePool/etc.] | [schema/composition/operator/mcp] | [field names] |

## PRD Alignment
[If PRD referenced: which ACs this advances, which decisions it implements]
[If no PRD: "No PRD linked — standalone change"]

## Decisions Made During Implementation
[Bullet list of any architectural choices made that are NOT already in a PRD.
These are candidates for `/kaos-prd-update-decisions` if a PRD exists.]

## Knowledge Captured
[What did we learn during this work that future agents should know?
Reference any patterns, gotchas, or conventions discovered.]

## Test Plan
[How to verify this change works. Include MCP tool calls if applicable:]
- [ ] `kaos:list(resource_type="[affected resource]")` shows expected state
- [ ] `kaos:validate(resource_type="[resource]", field="[field]", value="[value]")` passes
```

### Step 3: Knowledge Flywheel Check

Before finishing, ask:

> Are there any decisions or patterns from this work that should be captured in the PRD?
> If yes, suggest running `/kaos-prd-update-decisions [prd-id]`.
