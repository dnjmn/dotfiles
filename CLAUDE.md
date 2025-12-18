# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
- software installation should happen via scripts and at user level only

## Overview

Dotfiles repo for **one-command setup** on new machines. Supports **macOS** and **Linux**.

## Core Philosophy: Script Everything

**Goal**: `./install.sh --all` should fully configure a new machine with zero manual intervention.

If you can't script it, document the manual step in `docs/` with a `TODO: automate` note—but always try to automate first.

### Platform Support

| Platform | Package Manager | Status |
|----------|----------------|--------|
| macOS (Apple Silicon) | Homebrew | ✅ Supported |
| macOS (Intel) | Homebrew | ✅ Supported |
| Linux (Ubuntu/Debian) | Linuxbrew | ✅ Supported |

All software is installed at **user level** - no sudo/root required.

### What "Script Everything" Means

| Scenario | Approach |
|----------|----------|
| Installing a package | `pkg_install` (Homebrew/Linuxbrew abstraction) |
| Config files | Store in repo, symlink via script |
| Interactive installers | Use `--unattended`, `-y`, or heredoc for input |
| GUI-only settings | Export via `dconf dump`, `gsettings`, or config files |
| Secrets/API keys | Placeholder in repo + prompt user or source `~/.config/<tool>/secrets` |
| Plugin managers | Auto-install plugins in script (e.g., TPM's `run-shell ~/.tmux/plugins/tpm/bin/install_plugins`) |

### Script Requirements

Every `<tool>/install.sh` must be:
- **Idempotent** - Safe to run repeatedly (check before install)
- **Non-interactive** - No prompts; use defaults or flags
- **Self-contained** - Install dependencies within the script
- **Exit on error** - Use `set -e`

## Quick Reference

| Tool | Config | Install | Status |
|------|--------|---------|--------|
| Homebrew | `lib/platform.sh` | `homebrew/install.sh` | ✅ scripted |
| Kitty | `kitty/` → `~/.config/kitty/` | `kitty/install.sh` | ✅ scripted |
| Zsh | `zsh/` (ZDOTDIR) | `zsh/install.sh` | ✅ scripted |
| Tmux | `tmux/` → `~/.config/tmux/` | `tmux/install.sh` | ✅ scripted |
| Obsidian | `~/.config/obsidian/` | `obsidian/install.sh` | ✅ scripted |
| Neovim | `neovim/` → `~/.config/nvim/` | `neovim/install.sh` | ✅ scripted |
| LSD | `~/.config/lsd/` | `lsd/install.sh` | ✅ scripted |
| Notion | `~/.local/share/notion/` | `notion/install.sh` | ✅ scripted |
| Claude | `claude/` → `~/.claude/` | `claude/install.sh` | ✅ scripted |

## Commands

```bash
# Full setup (new machine)
./install.sh --all

# Interactive mode (choose tools)
./install.sh

# Single tool installation
./install.sh --zsh
./install.sh --kitty
./install.sh --tmux
./install.sh --obsidian
./install.sh --neovim
./install.sh --claude
./install.sh --homebrew
```

## Architecture

### `lib/platform.sh` - Shared Foundation

All install scripts source this file. It provides:

| Function | Purpose |
|----------|---------|
| `detect_os`, `is_macos`, `is_linux` | Platform detection |
| `detect_arch`, `is_arm64`, `is_x86_64` | Architecture detection |
| `ensure_homebrew`, `init_brew` | Homebrew setup (XDG-compliant, user-level) |
| `pkg_install`, `pkg_install_cask` | Idempotent package installation |
| `symlink_with_backup` | Safe symlink with automatic backup |
| `download_verified` | Download with optional SHA256 verification |
| `get_github_release_url`, `get_github_release_version` | GitHub release fetching |
| `print_info`, `print_ok`, `print_error`, `print_warn`, `print_step` | Consistent output formatting |

XDG variables are exported: `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_CACHE_HOME`, `$XDG_STATE_HOME`

### Install Script Pattern

Every `<tool>/install.sh` follows this structure:
1. Source `lib/platform.sh`
2. Ensure Homebrew available
3. Idempotency check (skip if already installed)
4. Install package via `pkg_install` or `pkg_install_cask`
5. Create XDG directories
6. Symlink config from repo to `~/.config/<tool>/`
7. Install plugins if applicable

## Rules for Claude

### Always
1. **Script first** - Automate before documenting manual steps
2. **Symlink configs** - Keep source of truth in repo
3. **XDG paths** - `~/.config`, `~/.local/share`, `~/.cache`, `~/.local/state`
4. **Update master** - Register new tools in root `install.sh`
5. **Document** - Create `docs/<tool>-setup.md`

### Never
- Leave manual steps without `TODO: automate`
- Hardcode absolute paths (use `$HOME`, `$XDG_CONFIG_HOME`)
- Put dotfiles in `~/` root
- Require user interaction during install

## Structure

```
<tool>/
├── install.sh          # Fully automated installer
├── *.conf              # Configs (symlinked to ~/.config/<tool>/)
└── templates/          # Optional templates

docs/
└── <tool>-setup.md     # Reference: shortcuts, troubleshooting, changelog
```

When adding a new tool, reference existing install scripts (e.g., `tmux/install.sh`, `kitty/install.sh`) as templates.

## Current Stack
- **Terminal**: Kitty + JetBrainsMono Nerd Font
- **Shell**: Zsh + Oh My Zsh + Powerlevel10k
- **Editor**: Neovim (LazyVim) + minuet-ai
- **Multiplexer**: Tmux + TPM
- **Notes**: Obsidian
- **AI**: Claude Code (custom agents + global instructions)
- **Theme**: Gruvbox Dark (all tools)
