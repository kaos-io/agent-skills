# Agent Definitions

An agent definition (`AGENT.md`) describes **what kind of agent to be** — its persona, capabilities, tool bindings, escalation rules, and knowledge consumption patterns.

Agent definitions are designed to be both **executable** (an AI assistant reads the AGENT.md and adopts the persona) and **extractable** (the Argo Workflow pipeline can vectorize the agent's domain expertise into the knowledge base).

## Directory Structure

```
agents/
└── release-manager/
    ├── manifest.json       # Registry manifest (required)
    ├── AGENT.md            # Agent definition (required)
    ├── EVAL.md             # Evaluation suite (optional, co-located)
    └── references/         # Supporting docs (optional)
```

## AGENT.md Format

```markdown
---
name: agent-name
description: What this agent does and when to use it.
---

# Agent Name

## Identity
[Who this agent is. Role, expertise, communication style.]

## Capabilities
[What this agent can do. Which MCP tools it uses and how.]

## Knowledge
[What domain context this agent needs. Which chunk_types it consumes
from the knowledge base via kaos:knowledge.]

## Workflow
[Step-by-step process this agent follows.]

## Escalation
[When this agent should hand off to a human or another agent.]

## Constraints
[Hard rules this agent must never violate.]
```

## Knowledge Flywheel

Agent definitions participate in the flywheel in two ways:

1. **As consumers** — they query the knowledge base for domain context before acting
2. **As producers** — the decisions and rationale embedded in their workflow sections are themselves vectorizable knowledge ("how does the release process work?")

The `manifest.json` declares both via `produces` and `consumes`.
