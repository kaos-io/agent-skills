# KAOS Agent Skills
 
Official agent skills for the [KAOS Agentic Operating System](https://kaos.kubecore.eu) — AI-powered Kubernetes infrastructure management.
 
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin%20marketplace-blueviolet)](https://code.claude.com/docs/en/plugin-marketplaces)
[![MCP](https://img.shields.io/badge/KAOS%20MCP-connected-orange)](https://kaos-mcp.dev.kaos.kubecore.eu/mcp)
 
---
 
## About
 
KAOS Skills teach AI coding agents how to work with the KAOS platform. The current skill set manages the full lifecycle of **Product Requirements Documents** — from creation through implementation to archival — keeping `knowledge/prds/` as a dynamic, accurate knowledge base that reflects current product state.
 
**Compatible with:** Claude Code · Codex CLI · Gemini CLI · Cursor · Windsurf · Aider
 
---
 
## Skills
 
| Skill | Command | When to Use |
|---|---|---|
| [`kaos-prd-create`](skills/kaos-prd-create/) | `/kaos-prd-create` | Starting a new PRD from a feature idea or design conversation |
| [`kaos-prd-start`](skills/kaos-prd-start/) | `/kaos-prd-start [id]` | Beginning active implementation on a validated PRD |
| [`kaos-prd-next`](skills/kaos-prd-next/) | `/kaos-prd-next [id]` | Identifying the single highest-priority task to work on |
| [`kaos-prd-update-progress`](skills/kaos-prd-update-progress/) | `/kaos-prd-update-progress [id]` | Recording completed work and verifying acceptance criteria |
| [`kaos-prd-update-decisions`](skills/kaos-prd-update-decisions/) | `/kaos-prd-update-decisions [id]` | Capturing design decisions made during implementation |
| [`kaos-prd-complete`](skills/kaos-prd-complete/) | `/kaos-prd-complete [id]` | Finalising a completed or closing an abandoned PRD |
 
### PRD Lifecycle
 
```
Idea / Design Session
        ↓
/kaos-prd-create          → Creates knowledge/prds/[id]-[name].md
                            Opens GitHub issue with PRD label
        ↓
[Resolve open questions, sign off architectural decisions]
        ↓
/kaos-prd-start           → Validates readiness
                            Checks platform state via KAOS MCP
                            Creates feature/prd-[id]-[name] branch
        ↓
/kaos-prd-next            → Recommends highest-priority task
                            Checks platform prerequisites via MCP
        ↓
[Implement]
        ↓
/kaos-prd-update-progress → Verifies ACs (MCP where possible)
                            Updates AC / threat / question statuses
        ↓
/kaos-prd-update-decisions → Captures decisions into PRD
                             Validates against kaos:schema
        ↓
[Repeat next / progress / decisions until all critical ACs pass]
        ↓
/kaos-prd-complete        → Archives PRD to knowledge/prds/done/
                            Updates and closes GitHub issue
```
 
---
 
## Installation
 
### Claude Code — Marketplace (recommended)
 
```bash
# Register the KAOS marketplace
/plugin marketplace add kaos-io/agent-skills
 
# Install all PRD skills at once
/plugin install kaos-prd-skills@kaos-agent-skills
 
# Or install individual skills
/plugin install kaos-prd-create@kaos-agent-skills
/plugin install kaos-prd-next@kaos-agent-skills
/plugin install kaos-prd-complete@kaos-agent-skills
```
 
### Manual
 
```bash
git clone https://github.com/kaos-io/agent-skills.git
 
# All PRD skills — global
cp -r agent-skills/skills/kaos-prd-* ~/.claude/skills/
 
# Project-scoped
cp -r agent-skills/skills/kaos-prd-* .claude/skills/
```
 
### Claude.ai
 
Upload individual `SKILL.md` files via **Settings → Skills**, or use the [Skills API](https://docs.claude.com/en/api/skills-guide).
 
---
 
## Prerequisites
 
These skills use the **KAOS MCP server** for platform verification. Add to your `~/.claude/claude.json`:
 
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
 
## Contributing
 
See [CONTRIBUTING.md](CONTRIBUTING.md). To add a new skill:
 
1. Copy `skills/template/` to `skills/your-skill-name/`
2. Edit `SKILL.md` with your instructions
3. Add an entry to `.claude-plugin/marketplace.json`
4. Open a pull request from a `feature/<skill-name>` branch
 
---
 
## License
 
[Apache 2.0](LICENSE)
 
---
 
[kaos.kubecore.eu](https://kaos.kubecore.eu) · [Agent Skills Spec](https://agentskills.io) · [Claude Code Plugin Docs](https://code.claude.com/docs/en/plugin-marketplaces)
