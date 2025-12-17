# Dotfiles

Cross-platform dotfiles and configurations for **macOS** and **Linux**.

This repository serves as a central location for all configuration files and setup documentation. Designed for quick setup on new machines with automated installation scripts.

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
