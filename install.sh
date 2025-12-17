#!/bin/bash

# Dotfiles - Master Installation Script
# Cross-platform setup for macOS and Linux
# This script helps you install and configure all developer tools
# Date: 2025-11-07

set -euo pipefail  # Fail fast: exit on error, undefined vars, pipe failures

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source platform helper
source "$SCRIPT_DIR/lib/platform.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print colored output
print_header() {
    echo ""
    echo -e "${BOLD}${MAGENTA}======================================"
    echo -e "$1"
    echo -e "======================================${NC}"
    echo ""
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Welcome message
clear
print_header "Developer Setup"
echo -e "${CYAN}Welcome to the Developer Setup script!${NC}"
echo "This script will help you install and configure developer tools."
echo ""
# Show platform info
OS_NAME="$(detect_os)"
ARCH_NAME="$(detect_arch)"
echo -e "${BOLD}Platform:${NC} ${OS_NAME} (${ARCH_NAME})"
echo ""
echo -e "${BOLD}Available installations:${NC}"
echo "  0. Homebrew (Package manager - prerequisite for other tools)"
echo "  1. Zsh Shell (with Oh My Zsh, Powerlevel10k, plugins)"
echo "  2. Kitty Terminal (GPU-accelerated terminal emulator)"
echo "  3. Tmux (Terminal multiplexer with sensible defaults)"
echo "  4. Obsidian (Knowledge base and note-taking)"
echo "  5. Neovim (LazyVim configuration)"
echo "  6. Claude Code (AI assistant configuration)"
echo "  7. All of the above"
echo ""

# Check if running in non-interactive mode
if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
    print_info "Running in non-interactive mode (installing all)"
    INSTALL_ALL=true
    INTERACTIVE=false
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --all         Install all tools without prompting"
    echo "  -h, --help        Show this help message"
    echo "  --homebrew        Install only Homebrew"
    echo "  --zsh             Install only Zsh"
    echo "  --kitty           Install only Kitty Terminal"
    echo "  --tmux            Install only Tmux"
    echo "  --obsidian        Install only Obsidian"
    echo "  --neovim          Install only Neovim"
    echo "  --claude          Install only Claude Code configs"
    echo ""
    echo "Examples:"
    echo "  ./install.sh              # Interactive mode"
    echo "  ./install.sh --all        # Install everything"
    echo "  ./install.sh --zsh        # Install only Zsh"
    echo "  ./install.sh --tmux       # Install only Tmux"
    echo "  ./install.sh --neovim     # Install only Neovim"
    echo "  ./install.sh --claude     # Install only Claude Code"
    exit 0
elif [ "$1" = "--homebrew" ]; then
    INSTALL_HOMEBREW=true
    INSTALL_ZSH=false
    INSTALL_KITTY=false
    INSTALL_TMUX=false
    INSTALL_OBSIDIAN=false
    INSTALL_NEOVIM=false
    INSTALL_CLAUDE=false
    INTERACTIVE=false
elif [ "$1" = "--zsh" ]; then
    INSTALL_HOMEBREW=false
    INSTALL_ZSH=true
    INSTALL_KITTY=false
    INSTALL_TMUX=false
    INSTALL_OBSIDIAN=false
    INSTALL_NEOVIM=false
    INSTALL_CLAUDE=false
    INTERACTIVE=false
elif [ "$1" = "--kitty" ]; then
    INSTALL_HOMEBREW=false
    INSTALL_ZSH=false
    INSTALL_KITTY=true
    INSTALL_TMUX=false
    INSTALL_OBSIDIAN=false
    INSTALL_NEOVIM=false
    INSTALL_CLAUDE=false
    INTERACTIVE=false
elif [ "$1" = "--tmux" ]; then
    INSTALL_HOMEBREW=false
    INSTALL_ZSH=false
    INSTALL_KITTY=false
    INSTALL_TMUX=true
    INSTALL_OBSIDIAN=false
    INSTALL_NEOVIM=false
    INSTALL_CLAUDE=false
    INTERACTIVE=false
elif [ "$1" = "--obsidian" ]; then
    INSTALL_HOMEBREW=false
    INSTALL_ZSH=false
    INSTALL_KITTY=false
    INSTALL_TMUX=false
    INSTALL_OBSIDIAN=true
    INSTALL_NEOVIM=false
    INSTALL_CLAUDE=false
    INTERACTIVE=false
elif [ "$1" = "--neovim" ]; then
    INSTALL_HOMEBREW=false
    INSTALL_ZSH=false
    INSTALL_KITTY=false
    INSTALL_TMUX=false
    INSTALL_OBSIDIAN=false
    INSTALL_NEOVIM=true
    INSTALL_CLAUDE=false
    INTERACTIVE=false
elif [ "$1" = "--claude" ]; then
    INSTALL_HOMEBREW=false
    INSTALL_ZSH=false
    INSTALL_KITTY=false
    INSTALL_TMUX=false
    INSTALL_OBSIDIAN=false
    INSTALL_NEOVIM=false
    INSTALL_CLAUDE=true
    INTERACTIVE=false
else
    INTERACTIVE=true
fi

# Interactive mode - ask user what to install
if [ "$INTERACTIVE" = true ]; then
    echo -e "${BOLD}What would you like to install?${NC}"
    echo ""

    # Homebrew
    while true; do
        read -p "Install Homebrew? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) INSTALL_HOMEBREW=true; break;;
            [Nn]* ) INSTALL_HOMEBREW=false; break;;
            * ) echo "Please answer y or n.";;
        esac
    done

    # Zsh
    while true; do
        read -p "Install Zsh? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) INSTALL_ZSH=true; break;;
            [Nn]* ) INSTALL_ZSH=false; break;;
            * ) echo "Please answer y or n.";;
        esac
    done

    # Kitty
    while true; do
        read -p "Install Kitty Terminal? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) INSTALL_KITTY=true; break;;
            [Nn]* ) INSTALL_KITTY=false; break;;
            * ) echo "Please answer y or n.";;
        esac
    done

    # Tmux
    while true; do
        read -p "Install Tmux? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) INSTALL_TMUX=true; break;;
            [Nn]* ) INSTALL_TMUX=false; break;;
            * ) echo "Please answer y or n.";;
        esac
    done

    # Obsidian
    while true; do
        read -p "Install Obsidian? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) INSTALL_OBSIDIAN=true; break;;
            [Nn]* ) INSTALL_OBSIDIAN=false; break;;
            * ) echo "Please answer y or n.";;
        esac
    done

    # Neovim
    while true; do
        read -p "Install Neovim? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) INSTALL_NEOVIM=true; break;;
            [Nn]* ) INSTALL_NEOVIM=false; break;;
            * ) echo "Please answer y or n.";;
        esac
    done

    # Claude Code
    while true; do
        read -p "Install Claude Code configs? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) INSTALL_CLAUDE=true; break;;
            [Nn]* ) INSTALL_CLAUDE=false; break;;
            * ) echo "Please answer y or n.";;
        esac
    done

    # Confirm
    echo ""
    print_info "Installation Summary:"
    [ "$INSTALL_HOMEBREW" = true ] && echo "  ✓ Homebrew"
    [ "$INSTALL_ZSH" = true ] && echo "  ✓ Zsh Shell"
    [ "$INSTALL_KITTY" = true ] && echo "  ✓ Kitty Terminal"
    [ "$INSTALL_TMUX" = true ] && echo "  ✓ Tmux"
    [ "$INSTALL_OBSIDIAN" = true ] && echo "  ✓ Obsidian"
    [ "$INSTALL_NEOVIM" = true ] && echo "  ✓ Neovim"
    [ "$INSTALL_CLAUDE" = true ] && echo "  ✓ Claude Code"
    echo ""

    while true; do
        read -p "Proceed with installation? (y/n): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* ) break;;
            [Nn]* ) print_warning "Installation cancelled."; exit 0;;
            * ) echo "Please answer y or n.";;
        esac
    done
elif [ "$INSTALL_ALL" = true ]; then
    INSTALL_HOMEBREW=true
    INSTALL_ZSH=true
    INSTALL_KITTY=true
    INSTALL_TMUX=true
    INSTALL_OBSIDIAN=true
    INSTALL_NEOVIM=true
    INSTALL_CLAUDE=true
fi

# Check if anything is selected
if [ "$INSTALL_HOMEBREW" != true ] && [ "$INSTALL_ZSH" != true ] && [ "$INSTALL_KITTY" != true ] && [ "$INSTALL_TMUX" != true ] && [ "$INSTALL_OBSIDIAN" != true ] && [ "$INSTALL_NEOVIM" != true ] && [ "$INSTALL_CLAUDE" != true ]; then
    print_warning "Nothing selected to install. Exiting."
    exit 0
fi

# Track installation status
INSTALLATIONS_SUCCEEDED=()
INSTALLATIONS_FAILED=()

# Install Homebrew (explicitly selected or as prerequisite)
if [ "$INSTALL_HOMEBREW" = true ]; then
    print_header "Installing Homebrew"

    if [ -f "$SCRIPT_DIR/homebrew/install.sh" ]; then
        if bash "$SCRIPT_DIR/homebrew/install.sh"; then
            INSTALLATIONS_SUCCEEDED+=("Homebrew")
            print_success "Homebrew installation completed"
        else
            INSTALLATIONS_FAILED+=("Homebrew")
            print_error "Homebrew installation failed"
        fi
    else
        print_error "Homebrew installation script not found at $SCRIPT_DIR/homebrew/install.sh"
        INSTALLATIONS_FAILED+=("Homebrew")
    fi
else
    # Ensure Homebrew is available as prerequisite for other tools
    print_header "System Setup"
    if is_macos; then
        print_step "Ensuring Xcode CLI tools are installed..."
        ensure_xcode_cli
    fi
    print_step "Ensuring Homebrew is installed..."
    ensure_homebrew
fi
# Initialize brew for this session
init_brew || true

# Install Zsh
if [ "$INSTALL_ZSH" = true ]; then
    print_header "Installing Zsh Shell"

    if [ -f "$SCRIPT_DIR/zsh/install.sh" ]; then
        if bash "$SCRIPT_DIR/zsh/install.sh"; then
            INSTALLATIONS_SUCCEEDED+=("Zsh Shell")
            print_success "Zsh installation completed"
        else
            INSTALLATIONS_FAILED+=("Zsh Shell")
            print_error "Zsh installation failed"
        fi
    else
        print_error "Zsh installation script not found at $SCRIPT_DIR/zsh/install.sh"
        INSTALLATIONS_FAILED+=("Zsh Shell")
    fi
fi

# Install Kitty Terminal
if [ "$INSTALL_KITTY" = true ]; then
    print_header "Installing Kitty Terminal"

    if [ -f "$SCRIPT_DIR/kitty/install.sh" ]; then
        if bash "$SCRIPT_DIR/kitty/install.sh"; then
            INSTALLATIONS_SUCCEEDED+=("Kitty Terminal")
            print_success "Kitty installation completed"
        else
            INSTALLATIONS_FAILED+=("Kitty Terminal")
            print_error "Kitty installation failed"
        fi
    else
        print_error "kitty/install.sh not found"
        INSTALLATIONS_FAILED+=("Kitty Terminal")
    fi
fi

# Install Tmux
if [ "$INSTALL_TMUX" = true ]; then
    print_header "Installing Tmux"

    if [ -f "$SCRIPT_DIR/tmux/install.sh" ]; then
        if bash "$SCRIPT_DIR/tmux/install.sh"; then
            INSTALLATIONS_SUCCEEDED+=("Tmux")
            print_success "Tmux installation completed"
        else
            INSTALLATIONS_FAILED+=("Tmux")
            print_error "Tmux installation failed"
        fi
    else
        print_error "Tmux installation script not found at $SCRIPT_DIR/tmux/install.sh"
        INSTALLATIONS_FAILED+=("Tmux")
    fi
fi

# Install Obsidian
if [ "$INSTALL_OBSIDIAN" = true ]; then
    print_header "Installing Obsidian"

    if [ -f "$SCRIPT_DIR/obsidian/install.sh" ]; then
        if bash "$SCRIPT_DIR/obsidian/install.sh"; then
            INSTALLATIONS_SUCCEEDED+=("Obsidian")
            print_success "Obsidian installation completed"
        else
            INSTALLATIONS_FAILED+=("Obsidian")
            print_error "Obsidian installation failed"
        fi
    else
        print_error "Obsidian installation script not found at $SCRIPT_DIR/obsidian/install.sh"
        INSTALLATIONS_FAILED+=("Obsidian")
    fi
fi

# Install Neovim
if [ "$INSTALL_NEOVIM" = true ]; then
    print_header "Installing Neovim"

    if [ -f "$SCRIPT_DIR/neovim/install.sh" ]; then
        if bash "$SCRIPT_DIR/neovim/install.sh"; then
            INSTALLATIONS_SUCCEEDED+=("Neovim")
            print_success "Neovim installation completed"
        else
            INSTALLATIONS_FAILED+=("Neovim")
            print_error "Neovim installation failed"
        fi
    else
        print_error "Neovim installation script not found at $SCRIPT_DIR/neovim/install.sh"
        INSTALLATIONS_FAILED+=("Neovim")
    fi
fi

# Install Claude Code configs
if [ "$INSTALL_CLAUDE" = true ]; then
    print_header "Installing Claude Code"

    if [ -f "$SCRIPT_DIR/claude/install.sh" ]; then
        if bash "$SCRIPT_DIR/claude/install.sh"; then
            INSTALLATIONS_SUCCEEDED+=("Claude Code")
            print_success "Claude Code setup completed"
        else
            INSTALLATIONS_FAILED+=("Claude Code")
            print_error "Claude Code setup failed"
        fi
    else
        print_error "Claude installation script not found at $SCRIPT_DIR/claude/install.sh"
        INSTALLATIONS_FAILED+=("Claude Code")
    fi
fi

# Summary
print_header "Installation Summary"

if [ ${#INSTALLATIONS_SUCCEEDED[@]} -gt 0 ]; then
    print_success "Successfully installed:"
    for item in "${INSTALLATIONS_SUCCEEDED[@]}"; do
        echo -e "  ${GREEN}✓${NC} $item"
    done
    echo ""
fi

if [ ${#INSTALLATIONS_FAILED[@]} -gt 0 ]; then
    print_error "Failed to install:"
    for item in "${INSTALLATIONS_FAILED[@]}"; do
        echo -e "  ${RED}✗${NC} $item"
    done
    echo ""
fi

# Post-installation notes
print_header "Next Steps"

if [ "$INSTALL_HOMEBREW" = true ]; then
    echo -e "${BOLD}Homebrew:${NC}"
    echo "  1. Verify: brew --version"
    echo "  2. Update: brew update"
    echo "  3. Install packages: brew install <package>"
    echo ""
fi

if [ "$INSTALL_ZSH" = true ]; then
    echo -e "${BOLD}Zsh:${NC}"
    echo "  1. Log out and log back in (or run: exec zsh)"
    echo "  2. Configure Powerlevel10k when prompted"
    echo "  3. Add secrets to: ~/.config/zsh/env.zsh"
    echo "  4. Customize config: ~/Developer/repos/dnjmn/dotfiles/zsh/.zshrc"
    echo ""
fi

if [ "$INSTALL_KITTY" = true ]; then
    echo -e "${BOLD}Kitty Terminal:${NC}"
    echo "  1. Reload config: Ctrl+Shift+F5"
    echo "  2. Change theme: kitty +kitten themes"
    echo "  3. See docs/kitty-terminal-setup.md for shortcuts"
    echo ""
fi

if [ "$INSTALL_TMUX" = true ]; then
    echo -e "${BOLD}Tmux:${NC}"
    echo "  1. Start tmux: tmux"
    echo "  2. Install plugins: Press Prefix + I (Ctrl+a then Shift+i)"
    echo "  3. Reload config: Press Prefix + r (Ctrl+a then r)"
    echo "  4. See docs/tmux-setup.md for keyboard shortcuts"
    echo ""
fi

if [ "$INSTALL_OBSIDIAN" = true ]; then
    echo -e "${BOLD}Obsidian:${NC}"
    echo "  1. Launch: obsidian (or from app menu)"
    echo "  2. Create a vault in ~/Documents/Obsidian/"
    echo "  3. See docs/obsidian-setup.md for shortcuts and plugins"
    echo ""
fi

if [ "$INSTALL_NEOVIM" = true ]; then
    echo -e "${BOLD}Neovim:${NC}"
    echo "  1. Launch: nvim"
    echo "  2. Plugins install automatically on first run"
    echo "  3. Check health: :checkhealth"
    echo "  4. See docs/neovim-setup.md for shortcuts"
    echo ""
fi

if [ "$INSTALL_CLAUDE" = true ]; then
    echo -e "${BOLD}Claude Code:${NC}"
    echo "  1. Run: claude"
    echo "  2. Configs linked from dotfiles to ~/.claude/"
    echo "  3. Custom agents available (debugger, reviewers, etc.)"
    echo "  4. See docs/claude-setup.md for details"
    echo ""
fi

print_info "Documentation available in the docs/ folder"
print_info "Repository: $SCRIPT_DIR"
echo ""

# Exit status
if [ ${#INSTALLATIONS_FAILED[@]} -eq 0 ]; then
    print_success "All installations completed successfully!"
    exit 0
else
    print_warning "Some installations had issues. Please check the output above."
    exit 1
fi
