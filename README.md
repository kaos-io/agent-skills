# KAOS Agent Skills

Official agentic artifact registry for the [KAOS Agentic Operating System](https://kaos.kubecore.eu) — AI-powered Kubernetes infrastructure management.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin%20marketplace-blueviolet)](https://code.claude.com/docs/en/plugin-marketplaces)
[![MCP](https://img.shields.io/badge/KAOS%20MCP-connected-orange)](https://kaos-mcp.dev.kaos.kubecore.eu/mcp)

---

## What This Is

A registry of reusable AI agent artifacts — skills, agent definitions, and prompt templates — that capture how humans work with the KAOS platform. Every artifact is designed to both **guide agent behavior** and **feed structured knowledge** into the KAOS RAG pipeline.

**The flywheel**: Humans work → agents capture decisions in structured formats → Argo Workflows extracts and vectorizes them → knowledge base grows → future agents make better decisions grounded in past rationale.

**Compatible with:** Claude Code · Codex CLI · Gemini CLI · Cursor · Windsurf · Aider

---

## Artifact Types

| Type | Entry File | Purpose | Example |
|---|---|---|---|
| **Skill** | `SKILL.md` | Step-by-step task instructions | PRD lifecycle management |
| **Agent** | `AGENT.md` | Agent persona, capabilities, workflow | Release manager |
| **Prompt** | `PROMPT.md` | Parameterised reusable prompts | PR review template |

Each artifact ships with a `manifest.json` that declares:
- **What it produces** — structured knowledge chunk types for the RAG pipeline
- **What it consumes** — knowledge and MCP tools it needs at runtime
- **Dependencies** — other artifacts it requires

See [manifest.schema.json](manifest.schema.json) for the full schema.

---

## Skills

| Skill | Command | What It Captures |
|---|---|---|
| [`kaos-prd-create`](plugins/kaos-prd-skills/skills/kaos-prd-create/) | `/kaos-prd-create` | Requirements, decisions, rationale, constraints |
| [`kaos-prd-start`](plugins/kaos-prd-skills/skills/kaos-prd-start/) | `/kaos-prd-start [id]` | Readiness validation, platform state |
| [`kaos-prd-next`](plugins/kaos-prd-skills/skills/kaos-prd-next/) | `/kaos-prd-next [id]` | Priority analysis, dependency mapping |
| [`kaos-prd-update-progress`](plugins/kaos-prd-skills/skills/kaos-prd-update-progress/) | `/kaos-prd-update-progress [id]` | Acceptance criteria verification |
| [`kaos-prd-update-decisions`](plugins/kaos-prd-skills/skills/kaos-prd-update-decisions/) | `/kaos-prd-update-decisions [id]` | Architectural decisions, design changes |
| [`kaos-prd-complete`](plugins/kaos-prd-skills/skills/kaos-prd-complete/) | `/kaos-prd-complete [id]` | Completion summary, archival |

### PRD Lifecycle

```
Idea / Design Session
        ↓
/kaos-prd-create          → Structured PRD at knowledge/prds/
                            GitHub issue with PRD label
                            → Argo Workflow extracts & vectorizes
        ↓
/kaos-prd-start           → Validates readiness via KAOS MCP
                            Creates implementation branch
        ↓
/kaos-prd-next            → Recommends task based on dependencies
                            + live platform state
        ↓
[Implement]
        ↓
/kaos-prd-update-progress → Verifies ACs against real state
/kaos-prd-update-decisions → Captures WHY decisions were made
        ↓
[Repeat until all critical ACs pass]
        ↓
/kaos-prd-complete        → Archives to knowledge/prds/done/
                            Knowledge preserved permanently
```

---

## Knowledge Pipeline Integration

Every PRD skill produces structured markdown with typed sections (`D-NN` decisions, `CON-NN` constraints, `AC-NN` criteria). These are extracted by the Argo Workflow pipeline triggered by the `PRD` GitHub issue label:

```
Skill produces structured PRD
    → GitHub issue labelled "PRD"
        → Argo Workflow webhook fires
            → Sections chunked by type (architectural-decision, constraint, etc.)
                → Vectorized into Milvus knowledge base
                    → Scored by last_updated for recency
                        → kaos:knowledge queries return relevant context
```

The `manifest.json` for each skill declares exactly which `chunk_types` it produces and consumes, making the data flow explicit and traceable.

---

## Installation

### Claude Code — Marketplace (recommended)

```bash
# Register the KAOS marketplace
/plugin marketplace add kaos-io/agent-skills

# Install all PRD skills at once
/plugin install kaos-prd-skills@kaos-agent-skills
```

### Manual

```bash
git clone https://github.com/kaos-io/agent-skills.git

# All PRD skills — global
cp -r agent-skills/plugins/kaos-prd-skills/skills/kaos-prd-* ~/.claude/skills/

# Project-scoped
cp -r agent-skills/plugins/kaos-prd-skills/skills/kaos-prd-* .claude/skills/
```

---

## Prerequisites

These artifacts use the **KAOS MCP server** for platform verification. Add to your `~/.claude/claude.json`:

```json
{
  "mcpServers": {
    "kaos": {
      "type": "url",
      "url": "https://kaos-mcp.dev.kaos.kubecore.eu/mcp"
    }
  }
}
```

A KAOS platform account is required — visit [kaos.kubecore.eu](https://kaos.kubecore.eu).

---

## Registry Index

The `index.json` at the repo root is an auto-generated catalog of all artifacts. It is regenerated by CI on every push and can be consumed by marketplace UIs and discovery tools.

```bash
# Regenerate locally
./scripts/generate-index.sh
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

[Apache 2.0](LICENSE)

---

[kaos.kubecore.eu](https://kaos.kubecore.eu) · [Agent Skills Spec](https://agentskills.io) · [Claude Code Plugin Docs](https://code.claude.com/docs/en/plugin-marketplaces)
