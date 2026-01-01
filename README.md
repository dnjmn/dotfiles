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

### Evidence

| Signal | What It Reveals |
|--------|-----------------|
| `ubuntu-setup` → `dotfiles` rename | Platform migration, portability priority |
| `lib/platform.sh` abstraction | Engineering mindset applied to dotfiles |
| No-sudo philosophy | Corporate/restricted environment adaptation |
| XDG compliance everywhere | Obsessive cleanliness, transferable configs |
| Claude co-authoring commits since Nov 26 | AI-assisted development is the default |
| `backstage-dev` plugin | Current work focus, domain knowledge capture |
| Multi-agent orchestration workflow | Self-replicating engineering process |

## Platform Support

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon) | ✅ Supported |
| macOS (Intel) | ✅ Supported |
| Linux (Ubuntu/Debian) | ✅ Supported |

All software is installed at **user level** - no sudo/root required.

## Quick Start

### Install Everything (Recommended for New Machines)
```bash
cd ~/Developer/repos/dnjmn/dotfiles
./install.sh --all
```

### Interactive Installation
```bash
cd ~/Developer/repos/dnjmn/dotfiles
./install.sh
```

You'll be prompted to select which tools to install.

### Install Individual Tools
```bash
# Install only Zsh
./install.sh --zsh

# Install only Kitty Terminal
./install.sh --kitty

# Install only Tmux
./install.sh --tmux

# Or use individual install scripts
cd zsh && ./install.sh
cd tmux && ./install.sh
```

## Structure

Each software/tool includes:
- Installation script for automated setup
- Configuration files (dotfiles)
- Documentation in the `docs/` folder

## Contents

- **Kitty Terminal** - Modern GPU-accelerated terminal emulator with Gruvbox theme
- **Zsh Shell** - Powerful shell with Oh My Zsh, Powerlevel10k, and productivity plugins (XDG compliant)
- **Tmux** - Terminal multiplexer with vim-style navigation, session persistence, and sensible defaults (XDG compliant)

## Documentation

See the [`docs/`](docs/) folder for detailed setup guides:

### Platform-Specific
- [macOS Setup Guide](docs/macos-setup.md) - macOS-specific instructions and troubleshooting

### Kitty Terminal
- [Kitty Terminal Setup](docs/kitty-terminal-setup.md)
- [Kitty Theme Changing Guide](docs/kitty-theme-changing-guide.md)
- [Kitty Troubleshooting](docs/kitty-troubleshooting.md)

### Zsh Shell
- [Zsh Setup](docs/zsh-setup.md)

### Tmux
- [Tmux Setup](docs/tmux-setup.md)

## First Time Setup

1. **Clone this repository:**
   ```bash
   mkdir -p ~/Developer/repos/dnjmn
   cd ~/Developer/repos/dnjmn
   git clone <your-repo-url> dotfiles
   cd dotfiles
   ```

2. **Run the master install script:**
   ```bash
   ./install.sh --all    # Install everything
   # or
   ./install.sh          # Interactive mode
   ```

3. **Follow post-installation steps:**
   - Log out and log back in if you installed Zsh
   - Configure Powerlevel10k when prompted
   - Add secrets to `~/.config/zsh/env.zsh`
   - Install Tmux plugins: Start tmux, then press `Ctrl+a` then `Shift+i`
   - Review documentation in `docs/` folder

## Features

- **XDG Compliant:** Keeps your home directory clean by following XDG Base Directory specification
- **Automated Installation:** One script to set up everything on a new machine
- **Version Controlled Dotfiles:** All configurations tracked in git
- **Comprehensive Documentation:** Every tool has detailed setup and troubleshooting guides
- **Fast Setup:** Get your development environment ready in minutes
