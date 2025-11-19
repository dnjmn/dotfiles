# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a dotfiles and Ubuntu configuration repository for developer productivity. It centralizes:
- Installation scripts for software/tools
- Configuration files (dotfiles)
- Documentation for all setup procedures

## Documentation Requirements

**CRITICAL**: All configuration changes MUST be documented in the `docs/` folder. Each software/tool should have:

1. **Setup Guide** (`docs/<tool>-setup.md`):
   - Installation date and version
   - What was installed and where
   - Key features and configuration highlights
   - Essential keyboard shortcuts (if applicable)
   - Configuration file locations
   - Recent configuration changes section

2. **Theme/Customization Guide** (if applicable):
   - How to customize the tool
   - Popular configurations or themes
   - Quick reference templates

3. **Troubleshooting Guide** (if applicable):
   - Document issues encountered during setup
   - Root cause analysis
   - Solutions applied
   - Verification steps

## Repository Structure

```
.
├── docs/                          # Documentation for all tools
│   ├── <tool>-setup.md
│   ├── <tool>-theme-guide.md
│   └── <tool>-troubleshooting.md
├── <tool>/                        # Tool-specific directory
│   ├── install.sh                 # Installation script
│   ├── config files               # Dotfiles for the tool
│   └── templates/                 # Template files
└── README.md
```

### XDG Base Directory Compliance

This repository follows the XDG Base Directory specification to keep the home directory clean:

- **XDG_CONFIG_HOME** (`~/.config`): User-specific configurations
- **XDG_DATA_HOME** (`~/.local/share`): User-specific data files
- **XDG_CACHE_HOME** (`~/.cache`): User-specific cache files
- **XDG_STATE_HOME** (`~/.local/state`): User-specific state data (logs, history)

When setting up new software, prefer XDG directories over placing files directly in `~/`.

## Current Software

### Kitty Terminal
- **Installed**: 2025-10-20, v0.43.1
- **Location**: `~/.local/kitty.app/`
- **Config**: `~/.config/kitty/kitty.conf`
- **Font**: JetBrainsMono Nerd Font 3.2.1
- **Theme**: Gruvbox Dark
- **Docs**:
  - `docs/kitty-terminal-setup.md`
  - `docs/kitty-theme-changing-guide.md`
  - `docs/kitty-troubleshooting.md`

### Zsh Shell
- **Installed**: 2025-11-07
- **Framework**: Oh My Zsh
- **Theme**: Powerlevel10k
- **XDG Compliant**: Yes
- **ZDOTDIR**: `~/Developer/repos/dnjmn/ubuntu-setup/zsh` (this repo)
- **Config Files**:
  - Main config: `zsh/.zshrc` (in repo)
  - Environment: `zsh/.zshenv` (in repo)
  - Home file: `~/.zshenv` (minimal, sets ZDOTDIR only)
  - Secrets: `~/.config/zsh/env.zsh` (not in repo, for API keys)
- **Oh My Zsh Location**: `~/.local/share/oh-my-zsh` (XDG_DATA_HOME)
- **History**: `~/.local/state/zsh/history` (XDG_STATE_HOME)
- **Cache**: `~/.cache/zsh/` (XDG_CACHE_HOME)
- **Plugins**:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - zsh-completions
  - z (directory jumping)
  - fzf (fuzzy finder)
  - git integration
- **Additional Tools**: fd, bat, tree
- **Docs**:
  - `docs/zsh-setup.md`

### Neovim
- **Installed**: 2025-11-13
- **Distribution**: LazyVim
- **Plugin Manager**: lazy.nvim
- **XDG Compliant**: Yes
- **Config Location**: `~/.config/nvim/` (XDG_CONFIG_HOME)
- **Data Location**: `~/.local/share/nvim/` (plugins, state)
- **Cache Location**: `~/.cache/nvim/`
- **Config Files**:
  - Entry point: `~/.config/nvim/init.lua`
  - Plugin specs: `~/.config/nvim/lua/plugins/*.lua`
  - Custom keymaps: `~/.config/nvim/lua/config/keymaps.lua`
  - Options: `~/.config/nvim/lua/config/options.lua`
- **Color Scheme**: Gruvbox Dark
- **Key Features**:
  - LSP support with mason.nvim
  - AI code completion with Claude Sonnet 4.5 (minuet-ai.nvim)
  - Floating terminal (85% size, CTRL+/)
  - Treesitter syntax highlighting
  - Git integration (gitsigns)
  - Modern UI (bufferline, lualine, which-key)
- **AI Completion**: minuet-ai.nvim using Claude Code OAuth credentials
- **Terminal Config**: `~/.config/nvim/lua/plugins/snacks.lua`
- **AI Config**: `~/.config/nvim/lua/plugins/minuet.lua`
- **Docs**:
  - `docs/neovim-setup.md`

### Tmux
- **Installed**: 2025-11-13
- **Plugin Manager**: TPM (Tmux Plugin Manager)
- **XDG Compliant**: Yes
- **Config**: `~/.config/tmux/tmux.conf` (symlinked from repo)
- **Plugins Location**: `~/.local/share/tmux/plugins/` (XDG_DATA_HOME)
- **Prefix Key**: Ctrl+a (changed from default Ctrl+b)
- **Theme**: Gruvbox Dark
- **Key Features**:
  - Vim-style pane navigation (hjkl)
  - Intuitive split keybindings (| and -)
  - Mouse support enabled
  - Session persistence (auto-save every 15 minutes)
  - Better copy/paste with system clipboard
  - 256 color support
- **Plugins**:
  - tmux-sensible (sensible defaults)
  - tmux-resurrect (save/restore sessions)
  - tmux-continuum (automatic session persistence)
  - tmux-yank (clipboard integration)
  - tmux-copycat (enhanced search)
- **Docs**:
  - `docs/tmux-setup.md`

## Installation Process

### Master Install Script

The repository includes a master installation script at the root (`install.sh`) that orchestrates all software installations:

**Usage:**
```bash
./install.sh --all      # Install everything (non-interactive)
./install.sh            # Interactive mode (prompts for each tool)
./install.sh --zsh      # Install only Zsh
./install.sh --kitty    # Install only Kitty
./install.sh --tmux     # Install only Tmux
```

**Features:**
- Interactive and non-interactive modes
- System update before installation
- Progress tracking and status reporting
- Error handling and installation summary
- Post-installation instructions

### Individual Install Scripts

Each tool has its own installation script in its directory:
- `zsh/install.sh` - Zsh with Oh My Zsh, Powerlevel10k, and plugins
- `tmux/install.sh` - Tmux with TPM and sensible defaults
- Future tools will follow the same pattern

## Working with This Repository

### Adding New Software

When installing new software:

1. Create tool directory: `<tool>/`
2. Create installation script: `<tool>/install.sh`
   - Should be idempotent (safe to run multiple times)
   - Should check if already installed
   - Should follow XDG Base Directory specification
   - Should use color-coded output (print_info, print_error, etc.)
3. Document the installation in `docs/<tool>-setup.md` including:
   - Installation date and version
   - Installation method
   - File locations
   - Configuration details
   - Key features enabled
4. If troubleshooting was needed, create `docs/<tool>-troubleshooting.md`
5. Update the README.md Contents section
6. Update CLAUDE.md Current Software section
7. Update the master `install.sh` script to include the new tool

### Modifying Configuration

When making configuration changes:

1. Update the configuration file
2. Document the change in the tool's setup guide under "Recent Configuration Changes"
3. Include the date and description of what was changed and why

### Documentation Style

- Use clear section headers
- Include file paths with line numbers when referencing specific config locations
- Provide commands in code blocks
- Document keyboard shortcuts in tables or lists
- Always include "Last updated" date at bottom
- Use examples and templates where helpful
- keep in mind that this folder is intended to help me whenever i switch to a new pc and would like to setup as fast as possible.
- always try to do things by scripts