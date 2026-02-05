# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Modular zsh configuration with Oh My Zsh, Powerlevel10k, and XDG Base Directory compliance. Only `~/.zshenv` lives in home directory; everything else is in ZDOTDIR (this directory).

## Commands

```bash
# Install zsh and all components
./install.sh

# Reload configuration after changes
exec zsh
# or
source .zshrc

# Reconfigure Powerlevel10k prompt
p10k configure
```

## Architecture

### File Loading Order

```
~/.zshenv                    # Sets ZDOTDIR, sources .zshenv below
  └─> .zshenv                # XDG vars, PATH, app configs, secrets
      └─> .zshrc             # Loads modules in order:
          ├─> config/*.zsh   # Shell settings (omz, fzf, keybindings)
          ├─> aliases/*.zsh  # Command shortcuts
          ├─> functions/*.zsh # Shell functions
          ├─> .p10k.zsh      # Prompt configuration
          └─> local.zsh      # Local overrides (not tracked)
```

### Module Categories

| Directory | Purpose | Examples |
|-----------|---------|----------|
| `config/` | Shell behavior & plugins | `omz.zsh` (plugins list), `fzf.zsh`, `golang.zsh` |
| `aliases/` | Command shortcuts | `git.zsh`, `docker.zsh`, `kubernetes.zsh` |
| `functions/` | Shell functions | `files.zsh`, `tools.zsh` |

### Key Files

- **`home-zshenv`** - Template copied to `~/.zshenv` (sets ZDOTDIR)
- **`.zshenv`** - Environment variables, XDG paths, PATH setup
- **`.zshrc`** - Module loader, P10K instant prompt
- **`config/omz.zsh`** - Oh My Zsh theme and plugins list
- **`xdg-env-template.zsh`** - Template for secrets file

### XDG Directory Mapping

| Content | Location |
|---------|----------|
| Oh My Zsh | `~/.local/share/oh-my-zsh` |
| History | `~/.local/state/zsh/history` |
| Cache/completions | `~/.cache/zsh/` |
| Secrets | `~/.config/zsh/env.zsh` |

## Conventions

**Adding new configuration:**
- Shell settings → `config/newconfig.zsh`
- Aliases → `aliases/newtool.zsh`
- Functions → `functions/newfuncs.zsh`

**Plugin order in `config/omz.zsh`:** `zsh-syntax-highlighting` must be last among external plugins.

**Local overrides:** Use `local.zsh` (gitignored) for machine-specific settings.
