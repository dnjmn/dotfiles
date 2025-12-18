# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform dotfiles for macOS and Linux. User-level installation (no sudo). XDG Base Directory compliant.

## Commands

```bash
# Full installation
./install.sh --all

# Individual tools
./install.sh --zsh
./install.sh --kitty
./install.sh --tmux
./install.sh --neovim
./install.sh --claude

# Direct module install
cd zsh && ./install.sh
```

## Architecture

```
dotfiles/
├── install.sh              # Master installer (interactive or --flags)
├── lib/platform.sh         # Cross-platform helpers (detect_os, pkg_install, symlink_with_backup)
├── {tool}/
│   ├── install.sh          # Tool-specific installer (sources lib/platform.sh)
│   └── config files        # Actual dotfiles
├── claude/
│   ├── agents/             # Custom Claude Code agents (debugger, reviewers)
│   └── plugins/            # Claude Code plugins with skills
└── docs/                   # Tool-specific documentation
```

### Key Patterns

**Platform abstraction** (`lib/platform.sh`):
- `is_macos`, `is_linux`, `is_arm64` - detection
- `pkg_install`, `pkg_install_cask` - Homebrew wrapper
- `symlink_with_backup` - safe linking with backup
- XDG vars exported: `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, `XDG_STATE_HOME`

**Install scripts** follow pattern:
1. Source `lib/platform.sh`
2. Ensure Homebrew via `ensure_homebrew`
3. Create XDG directories
4. Install package via `pkg_install`
5. Symlink configs via `symlink_with_backup`

**Zsh modular loading** (`.zshrc`):
- Loads from `$ZDOTDIR/{config,aliases,functions}/*.zsh`
- Local overrides in `$ZDOTDIR/local.zsh` (not tracked)

## XDG Paths

| Tool | Config Location |
|------|-----------------|
| Zsh | `~/.config/zsh/` |
| Tmux | `~/.config/tmux/tmux.conf` |
| Neovim | `~/.config/nvim/` |
| Kitty | `~/.config/kitty/kitty.conf` |

## Tool Defaults

- **Tmux prefix**: `Ctrl+a` (not Ctrl+b)
- **Kitty shell**: Auto-starts tmux (`tmux new-session -A -s main`)
- **Neovim**: LazyVim distribution
- **Theme**: Gruvbox Dark
