# Contributing to KAOS Agent Skills
 
Thanks for contributing! This guide covers everything you need to add or improve skills.
 
---
 
## Adding a New Skill
 
### 1. Create the skill folder
 
```bash
cp -r skills/template skills/your-skill-name
```
 
Skill folder names should be lowercase, hyphen-separated, and prefixed with `kaos-` if KAOS-specific.
 
### 2. Write the SKILL.md
 
The `SKILL.md` file has two parts:
 
**Frontmatter** — controls discovery (keep the description precise and trigger-rich):
```yaml
---
name: your-skill-name
description: What this skill does and exactly when Claude should use it.
---
```
 
**Body** — instructions Claude follows when the skill activates. See `skills/template/SKILL.md` for the structure.
 
**Tips for good descriptions:**
- Include trigger phrases users would naturally say
- Be specific about the domain (e.g. "KAOS KubePool", "Kubernetes")
- Mention the MCP tools used if relevant
 
### 3. Register in the marketplace
 
Add an entry to `.claude-plugin/marketplace.json` under `plugins`:
 
```json
{
  "name": "your-skill-name",
  "description": "One-line description shown in /plugin browse.",
  "skills": ["skills/your-skill-name"],
  "category": "productivity",
  "tags": ["kaos", "kubernetes", "relevant-tag"],
  "strict": false
}
```
 
Valid categories: `productivity`, `development`, `devops`, `security`, `data`, `communication`.
 
### 4. Open a pull request
 
- Branch name: `feature/<skill-name>`
- PR title: `Add skill: your-skill-name`
- Include a short description of what the skill does and example prompts that trigger it
 
---
 
## Improving an Existing Skill
 
- Edit `SKILL.md` directly and open a PR
- If changing the skill `name` in frontmatter, also update `marketplace.json`
 
---
 
## Skill Quality Checklist
 
- [ ] `name` is lowercase and hyphen-separated
- [ ] `description` includes trigger phrases and use cases
- [ ] Instructions are clear and testable
- [ ] At least 2 usage examples provided
- [ ] Entry added to `.claude-plugin/marketplace.json`
- [ ] Tested in Claude Code or Claude.ai
 
---
 
## Questions
 
Open an issue or reach out via [kaos.kubecore.eu](https://kaos.kubecore.eu).
