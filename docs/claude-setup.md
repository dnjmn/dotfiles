# Claude Code Setup

**Updated**: 2025-12-15

## Quick Install

```bash
./claude/install.sh      # Symlink configs
./claude/mcp-install.sh  # Add MCP servers (optional)
```

## What Gets Linked

| Source | Target | Description |
|--------|--------|-------------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | User instructions/memory |
| `claude/settings.json` | `~/.claude/settings.json` | User settings |
| `claude/agents/` | `~/.claude/agents/` | Custom subagents |
| `claude/commands/` | `~/.claude/commands/` | Slash commands |
| `claude/skills/` | `~/.claude/skills/` | Custom skills |
| `claude/rules/` | `~/.claude/rules/` | Path-scoped rules |
| `claude/hooks/` | `~/.claude/hooks/` | Hook scripts |

## NOT Version Controlled

These stay local in `~/.claude/` (generated/sensitive):
- `.credentials.json` - Auth tokens
- `history.jsonl` - Session history
- `projects/` - Project trust/caches
- `todos/`, `debug/`, `file-history/` - Runtime data
- `~/.claude.json` - MCP servers, OAuth sessions (sensitive)

## Custom Agents

### Core
| Agent | Description |
|-------|-------------|
| `debugger` | Root cause analysis for errors and test failures |
| `session-documenter` | Captures reusable insights |

### Reviewers (`agents/reviewers/`)
| Agent | Use For |
|-------|---------|
| `security-reviewer` | Code security, secrets, CVEs |
| `infra-reviewer` | Terraform, K8s, Dockerfiles |
| `arch-reviewer` | HLDs, ADRs, system design |
| `api-reviewer` | REST/gRPC endpoints, OpenAPI specs |

### Usage
```
> Use security-reviewer to audit internal/auth/
> Ask infra-reviewer to check the Kubernetes manifests
> Have arch-reviewer evaluate the system design
```

## MCP Servers

User-level MCP servers are stored in `~/.claude.json` (NOT version controlled - contains sensitive sessions).

### Adding MCP Servers

```bash
# Via script (pre-configured servers)
./claude/mcp-install.sh

# Or manually (user scope = available in all projects)
claude mcp add notion --scope user --transport sse https://mcp.notion.com/sse
claude mcp add playwright --scope user -- npx @anthropic-ai/mcp-server-playwright
claude mcp add github --scope user --transport http https://api.githubcopilot.com/mcp/

# List installed
claude mcp list

# Authenticate (for servers that need it)
/mcp  # In Claude Code
```

### MCP Scopes
| Scope | Location | Use |
|-------|----------|-----|
| `local` | `~/.claude.json` | Current project only |
| `project` | `.mcp.json` | Team-shared (git) |
| `user` | `~/.claude.json` | All your projects |

## Rules (Path-Scoped Instructions)

Create `claude/rules/<name>.md` for conditional instructions:

```markdown
---
paths: src/api/**/*.ts
---

# API Development Rules
- All endpoints need input validation
- Use standard error response format
```

## Hooks

Create scripts in `claude/hooks/` and configure in `settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/format.sh"}]
      }
    ]
  }
}
```

Hook events: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart`, `SessionEnd`

## Adding New Agents

1. Create `claude/agents/your-agent.md`:
```markdown
---
name: your-agent
description: What it does
tools: Read, Edit, Bash
---

You are...
```

2. Run `./claude/install.sh` to re-link

## Adding Custom Commands

1. Create `claude/commands/your-command.md`:
```markdown
---
description: What it does
allowed-tools: Bash(git:*)
---

Prompt content here...
Use $ARGUMENTS for user input.
```

2. Run `./claude/install.sh` to re-link
3. Use with `/your-command [args]`

## Adding Custom Skills

Skills are reusable capabilities Claude can invoke. Create `claude/skills/your-skill.md`:

```markdown
---
description: What this skill provides
---

Instructions for the skill...
```

Then re-run `./claude/install.sh` to re-link.

## Troubleshooting

**Configs not updating?**
```bash
ls -la ~/.claude/CLAUDE.md  # Should show symlink
./claude/install.sh         # Re-run to fix
```

**Override locally without affecting dotfiles?**
- Edit `~/.claude/settings.local.json` (not tracked)
- Create `./CLAUDE.local.md` in project root (auto-ignored)

## Changelog

| Date | Change |
|------|--------|
| 2025-12-15 | Added skills/ directory for custom skills |
| 2025-12-15 | Updated: accurate config paths, added rules/hooks, fixed MCP approach |
| 2025-11-27 | Initial setup with agents and settings |
