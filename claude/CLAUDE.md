# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Claude Code global configuration directory. Symlinked to `~/.claude/` via `install.sh`.

## Installation

```bash
./install.sh    # Symlinks ~/.claude → config/
```

## Directory Structure

`config/` becomes `~/.claude/` via symlink:

```
claude/
├── install.sh                # Installation script
└── config/ → ~/.claude/
    ├── .gitignore            # Ignores runtime files
    ├── CLAUDE.md             # Global instructions
    ├── settings.json         # Enabled plugins
    ├── statusline.sh         # P10k-style status line
    └── plugins/
        └── local/
            ├── backstage-dev/      # Backstage development workflows
            └── dnjmn-workflows/    # Personal workflow skills
                ├── plugin.json
                ├── commands/
                │   └── orchestrate.md
                └── skills/
```

## Key Components

### config/statusline.sh

P10k-style status line showing: directory (blue), git branch (yellow), model (cyan), context % (grey).

### config/CLAUDE.md

Global instructions loaded every session. Contains multi-agent orchestration triggers, auto-review rules, command references.

### Local Plugins

| Plugin | Purpose |
|--------|---------|
| `dnjmn-workflows` | `/orchestrate` command, DDD architecture, plugin patterns |
| `backstage-dev` | Backstage developer portal workflows |

## Enabled Plugins

From `config/settings.json`:
- commit-commands, feature-dev, code-review, pr-review-toolkit
- frontend-design, ralph-wiggum, hookify
- greptile, playwright, Notion, context7
- gopls-lsp, typescript-lsp

## Editing

All edits in `config/` are live immediately (symlinked to `~/.claude/`):

- **Global instructions**: `config/CLAUDE.md`
- **Plugin toggles**: `config/settings.json`
- **Custom plugins**: `config/plugins/local/<plugin-name>/`
