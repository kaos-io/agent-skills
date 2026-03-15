# Contributing to KAOS Agent Skills

Thanks for contributing! This repo is the **knowledge capture layer** of the KAOS platform — every artifact you add helps agents make better decisions grounded in human expertise.

---

## The Knowledge Flywheel

Before adding an artifact, understand the pattern:

```
Humans work → Agents capture decisions in structured formats
    → Argo Workflows extracts and vectorizes
        → Knowledge base grows
            → Future agents query it → Better decisions
```

Every artifact should answer: **what structured knowledge does this produce or consume?**

---

## Artifact Types

| Type | Entry File | Spec | Purpose |
|---|---|---|---|
| Skill | `SKILL.md` | [Agent Skills Spec](https://agentskills.io/specification) | Task instructions that produce structured output |
| Agent | `AGENT.md` | [agents/SPEC.md](agents/SPEC.md) | Agent persona, capabilities, workflow |
| Prompt | `PROMPT.md` | [prompts/SPEC.md](prompts/SPEC.md) | Parameterised reusable prompts |

---

## Adding Any Artifact

### 1. Create the directory

```
plugins/<plugin-name>/skills/<skill-name>/    # for skills in a plugin
agents/<agent-name>/                           # for agent definitions
prompts/<prompt-name>/                         # for prompt templates
```

Names: lowercase, hyphen-separated, prefixed with `kaos-` if KAOS-specific.

### 2. Write the entry file

Follow the spec for your artifact type. Key rules:

- **Frontmatter** with `name` and `description` (trigger-rich, specific)
- **Body** with clear, testable instructions
- **Token sizing**: 100-400 tokens per subsection (RAG pipeline constraint)

### 3. Create `manifest.json`

```json
{
  "$schema": "../../manifest.schema.json",
  "name": "your-artifact-name",
  "type": "skill",
  "version": "1.0.0",
  "entry": "SKILL.md",
  "description": "One-line description.",
  "produces": {
    "chunk_types": ["architectural-decision", "constraint"],
    "label": "PRD",
    "output_path": "knowledge/prds/"
  },
  "consumes": {
    "chunk_types": ["feature-requirement"],
    "tools": ["kaos:schema", "kaos:knowledge"]
  },
  "dependencies": {
    "skills": ["kaos-prd-create@^1.0.0"]
  },
  "tags": ["kaos", "relevant-tag"],
  "author": "kaos-io",
  "license": "Apache-2.0"
}
```

**`produces`** — what knowledge chunk types does this artifact generate for the RAG pipeline? If it doesn't produce structured knowledge, use empty `chunk_types`.

**`consumes`** — what MCP tools and knowledge types does this artifact need at runtime?

**`dependencies`** — what other artifacts must be available?

### 4. Register in marketplace (skills only)

For skills distributed via Claude Code plugins, add an entry to `.claude-plugin/marketplace.json`.

### 5. Validate

```bash
./scripts/generate-index.sh
```

This validates all manifests and regenerates `index.json`.

### 6. Open a pull request

- Branch: `feature/<artifact-name>`
- PR title: `Add <type>: <artifact-name>`
- Include example usage and what knowledge it captures

---

## Quality Checklist

- [ ] `name` is lowercase and hyphen-separated
- [ ] `description` includes trigger phrases and use cases
- [ ] `manifest.json` validates (`./scripts/generate-index.sh` passes)
- [ ] `produces` accurately declares what chunk types are generated
- [ ] `consumes` lists all MCP tools and knowledge types used
- [ ] Instructions are clear and testable
- [ ] Token sizing follows RAG pipeline constraints (100-400 tokens per subsection)
- [ ] Tested in Claude Code or Claude.ai

---

## Improving an Existing Artifact

- Edit the entry file directly and open a PR
- If changing `name` in frontmatter, also update `manifest.json` and `marketplace.json`
- Bump `version` in `manifest.json` following semver

---

## Questions

Open an issue or reach out via [kaos.kubecore.eu](https://kaos.kubecore.eu).
