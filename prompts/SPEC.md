# Prompt Templates

A prompt template (`PROMPT.md`) is a parameterised, reusable prompt for recurring workflows. Templates use `{{variables}}` that get hydrated at runtime with actual context.

Prompt templates standardise how teams interact with AI — ensuring consistent quality and capturing institutional knowledge about what makes a good prompt for a given task.

## Directory Structure

```
prompts/
└── pr-review/
    ├── manifest.json       # Registry manifest (required)
    ├── PROMPT.md           # Prompt template (required)
    ├── EVAL.md             # Evaluation suite (optional, co-located)
    └── examples/           # Example inputs/outputs (optional)
```

## PROMPT.md Format

```markdown
---
name: prompt-name
description: What this prompt does and when to use it.
---

# Prompt Name

## Context
[When to use this prompt. What problem it solves.]

## Variables

| Variable | Description | Required |
|---|---|---|
| `{{variable_name}}` | What this variable contains | Yes/No |

## Template

[The actual prompt text with {{variables}} to be filled in.]

## Examples

### Example 1: [Scenario]
**Input**: [Variable values]
**Expected Output**: [What good output looks like]
```

## Knowledge Flywheel

Prompt templates capture **how experts ask questions**. A senior engineer's PR review prompt embodies years of experience about what to look for. By templating and sharing it, that expertise is available to every team member and every agent.

The `manifest.json` declares:
- `produces.chunk_types` — if the prompt generates structured output that should be vectorized
- `consumes.chunk_types` — what knowledge the prompt expects to be available for grounding
