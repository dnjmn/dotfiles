# Dotfiles

Cross-platform dotfiles and configurations for **macOS** and **Linux**.

This repository serves as a central location for all configuration files and setup documentation. Designed for quick setup on new machines with automated installation scripts.

## Why This Project Exists

### The Surface Story
Reproducible development environment for a Platform Engineer. But that's table stakes.

### The Real Story: Three Inflection Points

**1. The Ubuntu Workstation Phase (Nov 2025)**

Originally `ubuntu-setup`. A Platform Engineer with 5+ years Go experience needed a repeatable dev environment. Initial choices reveal priorities:
- Zsh + Oh-My-Zsh + Powerlevel10k (productivity-focused shell)
- Tmux (session persistence for remote work)
- Neovim/LazyVim (keyboard-centric editing)
- XDG compliance from day one (clean `$HOME` obsession)

**2. The macOS Migration (Dec 2025)**

Major pivot: `lib/platform.sh` abstraction layer born. Rename from `ubuntu-setup` to `dotfiles`. The no-sudo philosophy suggests corporate-managed machines where root access is restricted. Linux support preserved for dev containers/VMs.

**3. The Claude Code Investment (Nov 27 → Present)**

Claude Code configuration went from basic to enterprise-grade:
- `backstage-dev` plugin (7,171 lines) with 5 agents, 8 commands, 7 skills
- MCP server for live Backstage Catalog API integration
- 6-phase multi-agent orchestration workflow
- PostToolUse hooks for automated validation

### The Deeper Why

**The Abstraction Ladder:**
| Layer | Time Saved |
|-------|-----------|
| Shell aliases | Microseconds per command |
| Zsh functions | Seconds per workflow |
| Install scripts | Hours per machine |
| Claude plugins | Days per feature |
| Multi-agent orchestration | Weeks per project |

Each layer builds on the one below. The dotfiles repo is the foundation for increasingly powerful automation.

**Single-Sentence Answer:** This project exists because the highest-leverage investment is encoding expertise into reusable systems—starting with shell config, culminating in AI agents that think like me while building a Backstage portal.

## Platform Support

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon) | ✅ Supported |
| macOS (Intel) | ✅ Supported |
| Linux (Ubuntu/Debian) | ✅ Supported |

All software is installed at **user level** - no sudo/root required.

## Quick Start

### Install Everything
```bash
cd ~/Developer/repos/dnjmn/dotfiles
for script in install/*.sh; do "$script"; done
```

### Install Individual Tools
```bash
# Core tools
./install/zsh.sh      # Shell with Oh-My-Zsh, Powerlevel10k
./install/tmux.sh     # Terminal multiplexer
./install/kitty.sh    # GPU-accelerated terminal
./install/neovim.sh   # Editor with LazyVim

# Development
./install/docker.sh   # Container runtime
./install/golang.sh   # Go toolchain

# Applications
./install/claude.sh   # Claude Code config
./install/obsidian.sh # Note-taking
./install/notion.sh   # Productivity
./install/ollama.sh   # Local LLMs
./install/lsd.sh      # Modern ls replacement
```

## Structure

```
dotfiles/
├── config/           # Configuration files (symlinked to ~/.config/)
│   ├── zsh/          # Shell config, aliases, functions
│   ├── tmux/         # tmux.conf, statusline
│   ├── kitty/        # Terminal config
│   ├── neovim/       # LazyVim config
│   └── claude/       # Claude Code settings, plugins
├── install/          # Per-tool install scripts
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
│   └── platform.sh   # Shared utilities
├── docs/             # Setup guides
├── CLAUDE.md         # Claude Code instructions
└── README.md
```

## Contents

- **Zsh Shell** - Oh My Zsh, Powerlevel10k, productivity plugins (XDG compliant)
- **Tmux** - Terminal multiplexer with vim-style navigation
- **Kitty Terminal** - GPU-accelerated terminal with Gruvbox theme
- **Neovim** - LazyVim configuration
- **Claude Code** - Custom plugins for Backstage development

## Documentation

See the [`docs/`](docs/) folder for detailed setup guides:

### Platform-Specific
- [macOS Setup Guide](docs/macos-setup.md)

### Tools
- [Zsh Setup](docs/zsh-setup.md)
- [Tmux Setup](docs/tmux-setup.md)
- [Kitty Terminal Setup](docs/kitty-terminal-setup.md)
- [Neovim Setup](docs/neovim-setup.md)

## First Time Setup

1. **Clone this repository:**
   ```bash
   mkdir -p ~/Developer/repos/dnjmn
   cd ~/Developer/repos/dnjmn
   git clone <your-repo-url> dotfiles
   cd dotfiles
   ```

2. **Install tools:**
   ```bash
   # Install everything
   for script in install/*.sh; do "$script"; done

   # Or pick what you need
   ./install/zsh.sh
   ./install/tmux.sh
   ```

3. **Post-installation:**
   - Log out and back in if you installed Zsh
   - Configure Powerlevel10k when prompted
   - Add secrets to `~/.config/zsh/env.zsh`
   - Install Tmux plugins: Start tmux, press `Ctrl+a` then `Shift+i`

## Features

- **XDG Compliant:** Keeps your home directory clean
- **No Orchestrator:** Run scripts directly, no magic
- **Per-Tool Scripts:** Each tool declares its own dependencies
- **Version Controlled:** All configurations tracked in git
