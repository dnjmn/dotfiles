#!/bin/bash

# Tmux Installation Script with XDG Base Directory Support
# Cross-platform: macOS and Linux (via Homebrew/Linuxbrew)
# This script installs and configures tmux with sensible defaults and TPM (Tmux Plugin Manager)
# Everything follows XDG Base Directory specification to keep home directory clean
# Date: 2025-11-13

set -e  # Exit on error

# Get script directory (where this install.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Tmux Setup Script (XDG Compliant)"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# Tmux directories
TMUX_CONFIG_DIR="$XDG_CONFIG_HOME/tmux"
TMUX_PLUGIN_DIR="$XDG_DATA_HOME/tmux/plugins"
TPM_DIR="$TMUX_PLUGIN_DIR/tpm"

print_info "Using XDG directory structure:"
echo "  • XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
echo "  • XDG_DATA_HOME: $XDG_DATA_HOME"
echo "  • XDG_STATE_HOME: $XDG_STATE_HOME"
echo "  • Tmux Config: $TMUX_CONFIG_DIR"
echo "  • Tmux Plugins: $TMUX_PLUGIN_DIR"
echo ""

# Ensure Homebrew is available
print_info "Ensuring Homebrew is available..."
ensure_homebrew
init_brew || true

# Create necessary XDG directories
print_step "Creating XDG directory structure..."
mkdir -p "$TMUX_CONFIG_DIR"
mkdir -p "$TMUX_PLUGIN_DIR"
print_info "XDG directories created"

# 1. Install tmux
print_step "Installing tmux package..."
if command -v tmux &> /dev/null; then
    print_warning "tmux is already installed ($(tmux -V))"
else
    pkg_install tmux
    print_info "tmux installed: $(tmux -V)"
fi

# 2. Copy tmux configuration
print_step "Setting up tmux configuration..."
if [ -f "$TMUX_CONFIG_DIR/tmux.conf" ]; then
    # Backup existing config
    cp "$TMUX_CONFIG_DIR/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Backed up existing tmux.conf"
fi

# Create symlink to our config in the repo
if [ -f "$SCRIPT_DIR/tmux.conf" ]; then
    ln -sf "$SCRIPT_DIR/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
    print_info "Linked tmux.conf from repo to $TMUX_CONFIG_DIR/tmux.conf"
else
    print_error "tmux.conf not found in $SCRIPT_DIR"
    exit 1
fi

# 3. Install TPM (Tmux Plugin Manager)
print_step "Installing TPM (Tmux Plugin Manager)..."
if [ -d "$TPM_DIR" ]; then
    print_warning "TPM is already installed at $TPM_DIR"
else
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    print_info "TPM installed to $TPM_DIR"
fi

# 4. Summary
echo ""
echo "======================================"
print_info "Tmux setup complete!"
echo "======================================"
echo ""
print_info "Directory Structure:"
echo "  • Config: $TMUX_CONFIG_DIR/tmux.conf"
echo "  • Plugins: $TMUX_PLUGIN_DIR"
echo "  • TPM: $TPM_DIR"
echo ""
print_info "Installed components:"
echo "  • Tmux: $(tmux -V)"
echo "  • TPM (Tmux Plugin Manager)"
echo ""
print_info "Next steps:"
echo "  1. Start a new tmux session: tmux"
echo "  2. Install plugins: Press Prefix + I (Ctrl+a then Shift+i)"
echo "  3. Reload config: Press Prefix + r (Ctrl+a then r)"
echo ""
print_info "Key bindings:"
echo "  • Prefix changed to: Ctrl+a (instead of Ctrl+b)"
echo "  • Split horizontal: Prefix + | (Ctrl+a then |)"
echo "  • Split vertical: Prefix + - (Ctrl+a then -)"
echo "  • Navigate panes: Prefix + hjkl (vim-style)"
echo "  • Resize panes: Prefix + HJKL (shift+hjkl)"
echo "  • New window: Prefix + c"
echo "  • Switch windows: Prefix + n/p or Prefix + number"
echo "  • Reload config: Prefix + r"
echo ""
print_warning "Note: All configs are in XDG directories, keeping your home directory clean!"
echo ""
