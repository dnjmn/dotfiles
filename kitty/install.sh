#!/bin/bash

# Kitty Terminal Installation Script with XDG Base Directory Support
# Installs Kitty terminal, JetBrainsMono Nerd Font, and configures everything
# Date: 2025-11-26

set -euo pipefail

echo "======================================"
echo "Kitty Terminal Setup (XDG Compliant)"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Kitty paths
KITTY_APP_DIR="$HOME/.local/kitty.app"
KITTY_BIN_DIR="$HOME/.local/bin"
KITTY_CONFIG_DIR="$XDG_CONFIG_HOME/kitty"
FONT_DIR="$XDG_DATA_HOME/fonts"
DESKTOP_DIR="$XDG_DATA_HOME/applications"

print_info "Using XDG directory structure:"
echo "  • Config: $KITTY_CONFIG_DIR"
echo "  • Fonts: $FONT_DIR"
echo "  • App: $KITTY_APP_DIR"
echo ""

# Create directories
print_step "Creating directories..."
mkdir -p "$KITTY_BIN_DIR"
mkdir -p "$KITTY_CONFIG_DIR"
mkdir -p "$FONT_DIR"
mkdir -p "$DESKTOP_DIR"

# 1. Install Kitty
print_step "Installing Kitty terminal..."
if command -v kitty &>/dev/null; then
    print_warning "Kitty already installed ($(kitty --version | head -1))"
else
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    print_info "Kitty installed"
fi

# Create symlinks to ~/.local/bin
print_step "Creating symlinks..."
ln -sf "$KITTY_APP_DIR/bin/kitty" "$KITTY_BIN_DIR/kitty"
ln -sf "$KITTY_APP_DIR/bin/kitten" "$KITTY_BIN_DIR/kitten"
print_info "Symlinks created in $KITTY_BIN_DIR"

# 2. Install JetBrainsMono Nerd Font
print_step "Installing JetBrainsMono Nerd Font..."

# Pinned version for reproducibility - update as needed
NERD_FONT_VERSION="v3.3.0"

install_jetbrains_font() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local zip_file="$tmp_dir/JetBrainsMono.zip"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.zip"

    print_info "Downloading JetBrainsMono Nerd Font ${NERD_FONT_VERSION}..."
    if ! curl -fsSL "$download_url" -o "$zip_file"; then
        print_error "Failed to download font"
        rm -rf "$tmp_dir"
        return 1
    fi

    print_info "Extracting fonts..."
    if ! unzip -q "$zip_file" -d "$tmp_dir"; then
        print_error "Failed to extract font archive"
        rm -rf "$tmp_dir"
        return 1
    fi

    # Copy only .ttf files (skip Windows-compatible and variable fonts)
    find "$tmp_dir" -name "*.ttf" ! -name "*Windows*" -exec cp {} "$FONT_DIR/" \;

    rm -rf "$tmp_dir"
    print_info "Font files installed to $FONT_DIR"
    return 0
}

if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    print_warning "JetBrainsMono Nerd Font already installed"
else
    if install_jetbrains_font; then
        fc-cache -f "$FONT_DIR"
        print_info "Font installed and cache updated"
    else
        print_warning "Font installation skipped - install manually from:"
        echo "  https://github.com/ryanoasis/nerd-fonts/releases"
    fi
fi

# 3. Symlink configuration
print_step "Linking configuration..."
if [ -f "$KITTY_CONFIG_DIR/kitty.conf" ] && [ ! -L "$KITTY_CONFIG_DIR/kitty.conf" ]; then
    cp "$KITTY_CONFIG_DIR/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Backed up existing kitty.conf"
fi
ln -sf "$SCRIPT_DIR/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf"
print_info "Config linked from repo"

# 4. Create desktop entry
print_step "Creating desktop entry..."
cat > "$DESKTOP_DIR/kitty.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Kitty
GenericName=Terminal Emulator
Comment=Fast, feature-rich, GPU based terminal
Exec=$KITTY_BIN_DIR/kitty
TryExec=$KITTY_BIN_DIR/kitty
Icon=kitty
Terminal=false
Categories=System;TerminalEmulator;
Keywords=terminal;shell;command line;
StartupWMClass=kitty
EOF

# Copy icon if available
if [ -f "$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png" ]; then
    mkdir -p "$XDG_DATA_HOME/icons/hicolor/256x256/apps"
    cp "$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png" \
       "$XDG_DATA_HOME/icons/hicolor/256x256/apps/kitty.png"
fi

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
print_info "Desktop entry created"

# Summary
echo ""
echo "======================================"
print_info "Kitty setup complete!"
echo "======================================"
echo ""
print_info "Installed:"
echo "  • Kitty: $(kitty --version 2>/dev/null | head -1 || echo 'check PATH')"
echo "  • Config: $KITTY_CONFIG_DIR/kitty.conf"
echo "  • Desktop: $DESKTOP_DIR/kitty.desktop"
echo ""
print_info "Key shortcuts:"
echo "  • New tab: Ctrl+Shift+T"
echo "  • New window: Ctrl+Shift+Enter"
echo "  • Reload config: Ctrl+Shift+F5"
echo ""
