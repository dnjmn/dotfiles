# macOS Setup Guide

**Platform**: macOS (Apple Silicon / Intel)

## Prerequisites

The install script will automatically install these if missing:

1. **Xcode Command Line Tools** - Required for git, compilers, etc.
2. **Homebrew** - Package manager for macOS

## Quick Start

```bash
# Clone the repo
git clone https://github.com/dnjmn/dotfiles.git ~/Developer/repos/dnjmn/dotfiles
cd ~/Developer/repos/dnjmn/dotfiles

# Run the installer
./install.sh --all
```

## Installation Methods

| Tool | macOS Method | Notes |
|------|--------------|-------|
| Zsh | `brew install` | macOS ships with zsh, but we install latest |
| Kitty | `brew install --cask` | Installs to /Applications |
| Tmux | `brew install` | Terminal multiplexer |
| Neovim | `brew install` | Editor |
| LSD | `brew install` | Modern ls replacement |
| Obsidian | `brew install --cask` | Note-taking app |
| Notion | `brew install --cask` | Productivity app |
| Claude | Symlinks only | Config files linked to ~/.claude/ |

## Key Differences from Linux

### Homebrew Paths

| Architecture | Homebrew Prefix |
|--------------|-----------------|
| Apple Silicon (M1/M2/M3/M4) | `/opt/homebrew` |
| Intel | `/usr/local` |

The `zsh/.zshenv` automatically detects and configures the correct path.

### Font Location

- **macOS**: `~/Library/Fonts/`
- **Linux**: `~/.local/share/fonts/`

### GUI App Installation

macOS uses Homebrew Cask for GUI applications:
- Apps install to `/Applications/`
- No desktop entry files needed
- Launch from Spotlight or Launchpad

### Keyboard Shortcuts

Kitty uses Cmd instead of Ctrl on macOS:
- New tab: `Cmd+T` (not Ctrl+Shift+T)
- New window: `Cmd+N` (not Ctrl+Shift+Enter)
- Reload config: `Ctrl+Cmd+,`

## Post-Installation

1. **Restart terminal** or run `exec zsh`
2. **Configure Powerlevel10k** when prompted
3. **Add secrets** to `~/.config/zsh/env.zsh`
4. **Install Tmux plugins**: Open tmux, press `Ctrl+a` then `I`

## Troubleshooting

### Homebrew not in PATH

If `brew` command not found after installation:

```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

This is automatically handled in `zsh/.zshenv`.

### Xcode CLI Tools Installation Stuck

If the Xcode CLI tools installation dialog doesn't appear:

```bash
xcode-select --install
# Or download from Apple Developer website
```

### Permission Issues

All installations are user-level. If you see permission errors:

```bash
# Check Homebrew ownership
ls -la $(brew --prefix)

# Fix if needed (should be owned by your user)
sudo chown -R $(whoami) $(brew --prefix)/*
```

## Version Information

Check installed versions:

```bash
brew --version          # Homebrew
zsh --version           # Zsh
kitty --version         # Kitty
tmux -V                 # Tmux
nvim --version          # Neovim
lsd --version           # LSD
```
