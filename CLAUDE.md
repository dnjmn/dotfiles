# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform dotfiles for macOS and Linux. User-level installation (no sudo). XDG Base Directory compliant.

## Commands

```bash
# Full installation
./install.sh --all

# Individual tools (or interactive: ./install.sh)
./install.sh --zsh
./install.sh --kitty
./install.sh --tmux
./install.sh --neovim
./install.sh --claude
./install.sh --go
./install.sh --docker
./install.sh --obsidian

# Direct module install
cd zsh && ./install.sh
```

## Architecture

Each `{tool}/` directory contains an `install.sh` that sources `lib/platform.sh` for cross-platform helpers.

**Install script pattern:**
1. Source `lib/platform.sh`
2. `ensure_homebrew` → `pkg_install <package>` → `symlink_with_backup`

**Platform helpers** (`lib/platform.sh`):
- Detection: `is_macos`, `is_linux`, `is_arm64`
- Packages: `pkg_install`, `pkg_install_cask` (Homebrew wrappers)
- Files: `symlink_with_backup`, `download_verified`

**Zsh modular loading** (`zsh/.zshrc`):
- Loads `$ZDOTDIR/{config,aliases,functions}/*.zsh` in order
- Local overrides in `$ZDOTDIR/local.zsh` (gitignored)

## XDG Paths

| Tool | Config Location |
|------|-----------------|
| Zsh | ZDOTDIR=`dotfiles/zsh/`, secrets in `~/.config/zsh/env.zsh` |
| Tmux | `~/.config/tmux/tmux.conf` |
| Neovim | `~/.config/nvim/` |
| Kitty | `~/.config/kitty/kitty.conf` |
| Go | `GOPATH=~/.local/share/go`, `GOBIN=~/.local/bin` |

## Tool Defaults

- **Tmux prefix**: `Ctrl+a` — install plugins with `Prefix + I` (Ctrl+a then Shift+i)
- **Kitty**: Auto-starts tmux session on launch
- **Neovim**: LazyVim distribution
- **Theme**: Gruvbox Dark
