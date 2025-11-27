# Claude Code Setup

**Installed**: 2025-11-27

## Quick Install
```bash
./claude/install.sh
```

## What Gets Linked

| Source | Target | Description |
|--------|--------|-------------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions |
| `claude/settings.json` | `~/.claude/settings.json` | Safe settings |
| `claude/mcp.json` | `~/.mcp.json` | MCP server definitions |
| `claude/agents/` | `~/.claude/agents/` | Custom subagents |
| `claude/commands/` | `~/.claude/commands/` | Slash commands (if any) |
| `claude/skills/` | `~/.claude/skills/` | Skills (if any) |
| `claude/output-styles/` | `~/.claude/output-styles/` | Output styles (if any) |

## Custom Agents

### Core
| Agent | Description |
|-------|-------------|
| `debugger` | Root cause analysis for errors and test failures |
| `session-documenter` | Captures reusable insights to `~/.claude-knowledge/` |

### Reviewers (`agents/reviewers/`)
| Agent | Use For |
|-------|---------|
| `security-reviewer` | Code security, secrets, CVEs |
| `infra-reviewer` | Terraform, K8s, Dockerfiles |
| `architecture-reviewer` | HLDs, ADRs, system design |
| `api-reviewer` | REST/gRPC endpoints, OpenAPI specs |

### Usage
```
> Use security-reviewer to audit internal/auth/
> Ask infra-reviewer to check the Kubernetes manifests
> Have architecture-reviewer evaluate docs/design/hld.md
```

## Config Details

### CLAUDE.md (Global Instructions)
Your personal preferences that apply to all Claude Code sessions:
- Concision and DRY principles
- Parallel subagent spawning
- Domain-driven design
- kubectl context rules

### settings.json
```json
{
  "alwaysThinkingEnabled": true
}
```

## Not Included (Runtime Data)
These stay local and are NOT symlinked:
- `.credentials.json` - Auth tokens
- `history.jsonl` - Session history
- `projects/` - Project-specific caches
- `todos/` - Task lists
- `file-history/` - File change history

## Adding New Agents

1. Create `claude/agents/your-agent.md`:
```markdown
---
name: your-agent
description: What it does
tools: Read, Edit, Bash
model: inherit
---

You are...
```

2. Run `./claude/install.sh` to re-link

## Adding Custom Commands

1. Create `claude/commands/your-command.md`:
```markdown
---
name: your-command
description: What it does
---

Prompt content here...
Use $ARGUMENTS for user input.
```

2. Run `./claude/install.sh` to re-link
3. Use with `/your-command [args]`

## Troubleshooting

**Configs not updating?**
```bash
ls -la ~/.claude/CLAUDE.md  # Should show symlink
./claude/install.sh         # Re-run to fix
```

**Want to override locally?**
Edit `~/.claude/settings.local.json` (not tracked in dotfiles)

## Changelog

| Date | Change |
|------|--------|
| 2025-11-27 | Initial setup with agents and settings |
