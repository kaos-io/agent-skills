# KAOS Agent Skills
 
Official agent skills for the [KAOS Agentic Operating System](https://kaos.kubecore.eu) — AI-powered Kubernetes infrastructure management.
 
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin%20marketplace-blueviolet)](https://code.claude.com/docs/en/plugin-marketplaces)
[![MCP](https://img.shields.io/badge/KAOS%20MCP-connected-orange)](https://kaos-mcp.dev.kaos.kubecore.eu/mcp)
 
---
 
## About
 
KAOS Skills teach AI coding agents how to work with the KAOS platform — from writing Product Requirements Documents to managing cloud-native infrastructure through natural language.
 
Each skill is a folder with a `SKILL.md` file. Claude automatically activates the right skill based on context.
 
**Compatible with:** Claude Code · Codex CLI · Gemini CLI · Cursor · Windsurf · Aider
 
---
 
## Skills
 
| Skill | Description |
|---|---|
| [`kaos-prd-next`](skills/kaos-prd-next/) | Generate structured PRDs for KAOS platform features and agentic infrastructure capabilities |
 
---
 
## Installation
 
### Claude Code — Marketplace (recommended)
 
```bash
# Register the KAOS marketplace
/plugin marketplace add kaos-io/agent-skills
 
# Install the PRD skill
/plugin install kaos-prd-next@kaos-agent-skills
```
 
### Manual
 
```bash
git clone https://github.com/kaos-io/agent-skills.git
 
# Global (all projects)
cp -r agent-skills/skills/kaos-prd-next ~/.claude/skills/
 
# Project-scoped
cp -r agent-skills/skills/kaos-prd-next .claude/skills/
```
 
### Claude.ai
 
Upload the `SKILL.md` file via **Settings → Skills**, or use the [Skills API](https://docs.claude.com/en/api/skills-guide).
 
---
 
## Usage
 
Once installed, just describe what you need:
 
```
> Write a PRD for a new KubePool autoscaling feature
 
> Create a product requirements document for the KAOS release manager
```
 
---
 
## Contributing
 
See [CONTRIBUTING.md](CONTRIBUTING.md). To add a new skill:
 
1. Copy `skills/template/` to `skills/your-skill-name/`
2. Edit `SKILL.md` with your instructions
3. Add an entry to `.claude-plugin/marketplace.json`
4. Open a pull request
 
---
 
## License
 
[Apache 2.0](LICENSE)
 
---
 
## Links
 
- [KAOS Platform](https://kaos.kubecore.eu)
- [Agent Skills Spec](https://agentskills.io) · [Claude Code Plugin Docs](https://code.claude.com/docs/en/plugin-marketplaces)
 
