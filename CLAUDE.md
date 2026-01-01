# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Cross-platform dotfiles for macOS and Linux. All software installs at user-level (no sudo). Follows XDG Base Directory specification.

## Commands

```bash
# Full setup
./install.sh --all

# Individual tools
./install.sh --zsh|--kitty|--tmux|--neovim|--claude|--docker|--go

# Interactive mode
./install.sh

# Homebrew packages
brew bundle --file=homebrew/Brewfile
```

## Architecture

### Directory Structure

```
├── install.sh              # Master installer - orchestrates all tool installs
├── lib/platform.sh         # Shared utilities: OS detection, pkg management, symlinks
├── homebrew/Brewfile       # All brew packages
├── zsh/                    # Shell config (XDG compliant)
│   ├── .zshrc/.zshenv      # Main configs
│   ├── aliases/            # Command aliases by category
│   ├── functions/          # Shell functions
│   └── config/             # Modular configs (exports, completions, etc.)
├── tmux/                   # tmux.conf + plugins
├── kitty/                  # kitty.conf + theme
├── neovim/                 # LazyVim config
├── claude/                 # Claude Code config
│   ├── config/             # Symlinked to ~/.claude/
│   │   ├── CLAUDE.md       # Global Claude instructions
│   │   ├── settings.json   # Plugin toggles
│   │   └── plugins/local/  # Custom plugins (backstage-dev, dnjmn-workflows)
│   └── install.sh          # Creates ~/.claude symlink
└── docs/                   # Setup guides per tool
```

### Key Patterns

**lib/platform.sh** - Source in any install script for:
- `detect_os()`, `is_macos()`, `is_linux()`
- `pkg_install()`, `pkg_install_cask()` - Homebrew wrappers
- `symlink_with_backup()` - Safe symlinking with backup
- `get_github_release_url()` - Fetch latest release URLs

**Install scripts** follow pattern:
1. Source `lib/platform.sh`
2. Check/install dependencies via Homebrew
3. Symlink configs to XDG locations
4. Print post-install steps

**XDG paths used:**
- `~/.config/` - configs (zsh, tmux, nvim, kitty)
- `~/.local/share/` - data, fonts
- `~/.local/bin/` - user binaries
- `~/.cache/` - cache files

## When Editing

- Test changes on macOS (primary) - Linux paths differ for casks
- `lib/platform.sh` changes affect all install scripts
- Claude configs in `claude/config/` are live (symlinked to `~/.claude/`)
- Zsh changes: run `exec zsh` to reload
- Tmux changes: `prefix + r` to reload (prefix = Ctrl+a)
