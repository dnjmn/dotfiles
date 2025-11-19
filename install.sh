#!/bin/bash

# Ubuntu Setup - Master Installation Script
# This script helps you install and configure all developer tools
# Date: 2025-11-07

set -e  # Exit on error

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Welcome message
clear
print_header "Ubuntu Developer Setup"
echo -e "${CYAN}Welcome to the Ubuntu Developer Setup script!${NC}"
echo "This script will help you install and configure developer tools."
echo ""
echo -e "${BOLD}Available installations:${NC}"
echo "  1. Zsh Shell (with Oh My Zsh, Powerlevel10k, plugins)"
echo "  2. Kitty Terminal (GPU-accelerated terminal emulator)"
echo "  3. Tmux (Terminal multiplexer with sensible defaults)"
echo "  4. All of the above"
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
    echo "  --zsh             Install only Zsh"
    echo "  --kitty           Install only Kitty Terminal"
    echo "  --tmux            Install only Tmux"
    echo ""
    echo "Examples:"
    echo "  ./install.sh              # Interactive mode"
    echo "  ./install.sh --all        # Install everything"
    echo "  ./install.sh --zsh        # Install only Zsh"
    echo "  ./install.sh --tmux       # Install only Tmux"
    exit 0
elif [ "$1" = "--zsh" ]; then
    INSTALL_ZSH=true
    INSTALL_KITTY=false
    INSTALL_TMUX=false
    INTERACTIVE=false
elif [ "$1" = "--kitty" ]; then
    INSTALL_ZSH=false
    INSTALL_KITTY=true
    INSTALL_TMUX=false
    INTERACTIVE=false
elif [ "$1" = "--tmux" ]; then
    INSTALL_ZSH=false
    INSTALL_KITTY=false
    INSTALL_TMUX=true
    INTERACTIVE=false
else
    INTERACTIVE=true
fi

# Interactive mode - ask user what to install
if [ "$INTERACTIVE" = true ]; then
    echo -e "${BOLD}What would you like to install?${NC}"
    echo ""

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

    # Confirm
    echo ""
    print_info "Installation Summary:"
    [ "$INSTALL_ZSH" = true ] && echo "  ✓ Zsh Shell"
    [ "$INSTALL_KITTY" = true ] && echo "  ✓ Kitty Terminal"
    [ "$INSTALL_TMUX" = true ] && echo "  ✓ Tmux"
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
    INSTALL_ZSH=true
    INSTALL_KITTY=true
    INSTALL_TMUX=true
fi

# Check if anything is selected
if [ "$INSTALL_ZSH" != true ] && [ "$INSTALL_KITTY" != true ] && [ "$INSTALL_TMUX" != true ]; then
    print_warning "Nothing selected to install. Exiting."
    exit 0
fi

# System update
print_header "System Update"
print_step "Updating package lists..."
sudo apt update

# Track installation status
INSTALLATIONS_SUCCEEDED=()
INSTALLATIONS_FAILED=()

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

    print_warning "Kitty Terminal installation is manual."
    print_info "Please follow the instructions in docs/kitty-terminal-setup.md"
    echo ""
    echo "Quick instructions:"
    echo "  1. Download and install Kitty:"
    echo "     curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin"
    echo ""
    echo "  2. Create symlinks:"
    echo "     ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/"
    echo "     ln -sf ~/.local/kitty.app/bin/kitten ~/.local/bin/"
    echo ""
    echo "  3. Download JetBrainsMono Nerd Font from:"
    echo "     https://github.com/ryanoasis/nerd-fonts/releases"
    echo ""
    echo "  4. Configure Kitty (config in ~/.config/kitty/kitty.conf)"
    echo ""

    INSTALLATIONS_SUCCEEDED+=("Kitty Terminal (manual steps required)")
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

if [ "$INSTALL_ZSH" = true ]; then
    echo -e "${BOLD}Zsh:${NC}"
    echo "  1. Log out and log back in (or run: exec zsh)"
    echo "  2. Configure Powerlevel10k when prompted"
    echo "  3. Add secrets to: ~/.config/zsh/env.zsh"
    echo "  4. Customize config: ~/Developer/repos/dnjmn/ubuntu-setup/zsh/.zshrc"
    echo ""
fi

if [ "$INSTALL_KITTY" = true ]; then
    echo -e "${BOLD}Kitty Terminal:${NC}"
    echo "  1. Complete manual installation steps above"
    echo "  2. Configure theme and settings"
    echo "  3. See docs/kitty-terminal-setup.md for details"
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
