# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Cross-platform dotfiles for macOS and Linux. All software installs at user-level (no sudo). Follows XDG Base Directory specification.

## Commands

```bash
# Install a single tool
./install/zsh.sh
./install/tmux.sh
./install/kitty.sh
./install/neovim.sh
./install/claude.sh
./install/docker.sh
./install/golang.sh

# Install everything
for script in install/*.sh; do "$script"; done
```

## Architecture

### Directory Structure

```
dotfiles/
├── config/               # Configuration files
│   ├── zsh/              # Shell config (XDG compliant)
│   │   ├── .zshrc        # Main config
│   │   ├── .zshenv       # Environment variables
│   │   ├── aliases/      # Command aliases by category
│   │   ├── functions/    # Shell functions
│   │   └── config/       # Modular configs
│   ├── tmux/             # tmux.conf + statusline
│   ├── kitty/            # kitty.conf + session
│   ├── neovim/           # LazyVim config
│   └── claude/           # Claude Code config
│       ├── CLAUDE.md     # Global Claude instructions
│       ├── settings.json # Plugin toggles
│       └── plugins/local/# Custom plugins
├── install/              # Per-tool install scripts
│   ├── zsh.sh
│   ├── tmux.sh
│   ├── kitty.sh
│   ├── neovim.sh
│   ├── claude.sh
│   ├── docker.sh
│   ├── golang.sh
│   ├── ollama.sh
│   ├── obsidian.sh
│   ├── notion.sh
│   └── lsd.sh
├── lib/
│   └── platform.sh       # Shared utilities
└── docs/                 # Setup guides
```

### Key Patterns

**lib/platform.sh** - Source in any install script for:
- `has()` - Check if command exists
- `detect_os()`, `is_macos()`, `is_linux()`
- `pkg_install()`, `pkg_install_cask()` - Homebrew wrappers
- `symlink_with_backup()` - Safe symlinking with backup
- `get_github_release_url()` - Fetch latest release URLs

**Install script template:**
```bash
#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="<tool>"
readonly CONFIG_DIR="$REPO_ROOT/config/$NAME"
readonly DEPS=(<packages>)

install_deps() { ... }
link_configs() { ... }
post_install() { ... }

main() {
    echo "==> Installing $NAME"
    install_deps
    link_configs
    post_install
    echo "==> Done"
}

main "$@"
```

**XDG paths used:**
- `~/.config/` - configs (zsh, tmux, nvim, kitty, claude)
- `~/.local/share/` - data, fonts
- `~/.local/bin/` - user binaries
- `~/.cache/` - cache files

## When Editing

- Test changes on macOS (primary) - Linux paths differ for casks
- `lib/platform.sh` changes affect all install scripts
- Claude configs in `config/claude/` are live (symlinked to `~/.claude/`)
- Zsh changes: run `exec zsh` to reload
- Tmux changes: `prefix + r` to reload (prefix = Ctrl+a)
